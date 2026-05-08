# frozen_string_literal: true

require 'fastlane/action'
require 'net/http'
require 'json'

module Fastlane
  module Actions
    class OpenaiAskAction < Action
      OPENAI_API_ENDPOINT = URI('https://api.openai.com/v1/chat/completions').freeze
      DEFAULT_MAX_TOOL_ITERATIONS = 5

      PREDEFINED_PROMPTS = {
        release_notes: <<~PROMPT
          Act like a mobile app marketer who wants to prepare release notes for Google Play and App Store.
          Do not write it point by point and keep it under 350 characters. It should be a unique paragraph.

          When provided a list, use the number of any potential "*" in brackets at the start of each item as indicator of importance.
          Ignore items starting with "[Internal]", and ignore links to GitHub.
        PROMPT
      }.freeze

      def self.run(params)
        api_token = params[:api_token]
        prompt = params[:prompt]
        prompt = PREDEFINED_PROMPTS[prompt] if PREDEFINED_PROMPTS.key?(prompt)
        question = params[:question]
        tools = params[:tools]
        tool_handlers = params[:tool_handlers] || {}
        max_tool_iterations = params[:max_tool_iterations] || DEFAULT_MAX_TOOL_ITERATIONS

        headers = {
          'Content-Type': 'application/json',
          Authorization: "Bearer #{api_token}"
        }

        # Backwards-compatible single-shot path when no tools are provided.
        if tools.nil? || tools.empty?
          body = request_body(prompt: prompt, question: question)
          response = Net::HTTP.post(OPENAI_API_ENDPOINT, body, headers)
          return parse_text_response(response)
        end

        run_with_tools(
          prompt: prompt,
          question: question,
          tools: tools,
          tool_handlers: tool_handlers,
          max_tool_iterations: max_tool_iterations,
          headers: headers
        )
      end

      def self.run_with_tools(prompt:, question:, tools:, tool_handlers:, max_tool_iterations:, headers:)
        messages = [
          format_message(role: 'system', text: prompt),
          format_message(role: 'user', text: question),
        ].compact

        max_tool_iterations.times do
          body = request_body_with_messages(messages: messages, tools: tools)
          response = Net::HTTP.post(OPENAI_API_ENDPOINT, body, headers)
          assistant_message = parse_assistant_message(response)
          tool_calls = assistant_message['tool_calls']

          # No tool calls — model produced a final answer.
          return assistant_message['content'] if tool_calls.nil? || tool_calls.empty?

          # Append the assistant's tool-call message verbatim, then run each handler
          # and append the corresponding `role: tool` results.
          messages << assistant_message
          tool_calls.each do |tool_call|
            messages << execute_tool_call(tool_call, tool_handlers)
          end
        end

        UI.user_error!(
          "OpenAI tool-use loop did not terminate after #{max_tool_iterations} iterations. " \
          'Increase `max_tool_iterations` or check that your prompt instructs the model to stop calling tools.'
        )
      end

      def self.request_body(prompt:, question:)
        {
          model: 'gpt-4o',
          response_format: { type: 'text' },
          temperature: 1,
          max_tokens: 2048,
          top_p: 1,
          messages: [
            format_message(role: 'system', text: prompt),
            format_message(role: 'user', text: question),
          ].compact
        }.to_json
      end

      def self.request_body_with_messages(messages:, tools:)
        {
          model: 'gpt-4o',
          response_format: { type: 'text' },
          temperature: 1,
          max_tokens: 2048,
          top_p: 1,
          messages: messages,
          tools: tools
        }.to_json
      end

      def self.format_message(role:, text:)
        return nil if text.nil? || text.empty?

        {
          role: role,
          content: [{ type: 'text', text: text }]
        }
      end

      def self.parse_text_response(response)
        case response
        when Net::HTTPOK
          json = JSON.parse(response.body)
          json['choices']&.first&.dig('message', 'content')
        else
          UI.user_error!("Error in OpenAI API response: #{response}. #{response.body}")
        end
      end

      def self.parse_assistant_message(response)
        case response
        when Net::HTTPOK
          json = JSON.parse(response.body)
          json['choices']&.first&.dig('message') || {}
        else
          UI.user_error!("Error in OpenAI API response: #{response}. #{response.body}")
        end
      end

      def self.execute_tool_call(tool_call, tool_handlers)
        name = tool_call.dig('function', 'name')
        raw_args = tool_call.dig('function', 'arguments') || '{}'
        args =
          begin
            JSON.parse(raw_args)
          rescue JSON::ParserError => e
            { '__error__' => "Invalid JSON arguments: #{e.message}" }
          end

        handler = tool_handlers[name]
        result =
          if handler
            handler.call(args)
          else
            { error: "No handler defined for tool '#{name}'" }
          end

        {
          role: 'tool',
          tool_call_id: tool_call['id'],
          content: result.to_json
        }
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Use OpenAI API to generate response to a prompt'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'The response text from the prompt as returned by OpenAI API. ' \
          'When `tools` are provided, returns the assistant content from the first turn that produces a non-tool-call response.'
      end

      def self.details
        <<~DETAILS
          Uses the OpenAI API to generate response to a prompt.
          Can be used to e.g. ask it to generate Release Notes based on a bullet point technical changelog or similar.

          When `tools` and `tool_handlers` are provided, the action runs a tool-use (function-calling) loop:
          on each turn, if the model calls one or more tools, the corresponding handler is invoked locally
          and its return value is sent back to the model as a `role: tool` message. The loop ends when the
          model returns a plain text response, or when `max_tool_iterations` is reached.
        DETAILS
      end

      def self.examples
        [
          <<~'EXEMPLE',
            items = extract_release_notes_for_version(version: app_version, release_notes_file_path: 'RELEASE-NOTES.txt')
            nice_changelog = openai_ask(
              prompt: :release_notes, # Uses the pre-crafted prompt for App Store / Play Store release notes
              question: "Help me write release notes for the following items:\n#{items}",
              api_token: get_required_env('OPENAI_API_TOKEN')
            )
            File.write(File.join('fastlane', 'metadata', 'android', 'en-US', 'changelogs', 'default.txt'), nice_changelog)
          EXEMPLE
          <<~'EXEMPLE',
            # Tool-use loop: the model proposes release notes via a tool call; the handler validates
            # length locally and rejects until the model produces text under the limit.
            notes = openai_ask(
              prompt: :release_notes,
              question: "Write release notes for: #{items}. Use the submit_notes tool to submit your draft.",
              api_token: get_required_env('OPENAI_API_TOKEN'),
              tools: [{
                type: 'function',
                function: {
                  name: 'submit_notes',
                  description: 'Submits the proposed release notes for length validation.',
                  parameters: {
                    type: 'object',
                    properties: { text: { type: 'string' } },
                    required: ['text']
                  }
                }
              }],
              tool_handlers: {
                'submit_notes' => ->(args) {
                  len = args['text'].length
                  len <= 350 ? { ok: true, length: len } : { ok: false, length: len, max: 350 }
                }
              }
            )
          EXEMPLE
        ]
      end

      def self.available_prompt_symbols
        PREDEFINED_PROMPTS.keys.map { |v| "`:#{v}`" }.join(',')
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :prompt,
                                       description: 'The internal top-level instructions to give to the model to tell it how to behave. ' \
                                        + "Use a Ruby Symbol from one of [#{available_prompt_symbols}] to use a predefined prompt instead of writing your own",
                                       optional: true,
                                       default_value: nil,
                                       type: String,
                                       skip_type_validation: true,
                                       verify_block: proc do |value|
                                         next if value.is_a?(String)
                                         next if PREDEFINED_PROMPTS.include?(value)

                                         UI.user_error!("Parameter `prompt` can only be a String or one of the following Symbols: [#{available_prompt_symbols}]")
                                       end),
          FastlaneCore::ConfigItem.new(key: :question,
                                       description: 'The user message to ask the question to the OpenAI model',
                                       optional: false,
                                       default_value: nil,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       description: 'The OpenAI API Token to use for the request',
                                       env_name: 'OPENAI_API_TOKEN',
                                       optional: false,
                                       sensitive: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :tools,
                                       description: 'Optional array of tool (function-calling) definitions in OpenAI format. ' \
                                                    'When provided, the action runs a tool-use loop',
                                       optional: true,
                                       default_value: nil,
                                       type: Array,
                                       skip_type_validation: true),
          FastlaneCore::ConfigItem.new(key: :tool_handlers,
                                       description: 'Hash of tool name to a callable (e.g. a Proc) invoked when the model calls that tool. ' \
                                                    'The callable receives the parsed arguments Hash and must return a JSON-serializable value, ' \
                                                    'which is sent back to the model as the tool result',
                                       optional: true,
                                       default_value: nil,
                                       type: Hash,
                                       skip_type_validation: true),
          FastlaneCore::ConfigItem.new(key: :max_tool_iterations,
                                       description: 'Maximum number of tool-use loop iterations before the action fails. ' \
                                                    'Only used when `tools` are provided',
                                       optional: true,
                                       default_value: DEFAULT_MAX_TOOL_ITERATIONS,
                                       type: Integer),
        ]
      end

      def self.is_supported?(_platform)
        true
      end
    end
  end
end
