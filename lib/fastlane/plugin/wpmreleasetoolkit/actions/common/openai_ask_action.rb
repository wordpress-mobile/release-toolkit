# frozen_string_literal: true

require 'fastlane/action'
require 'net/http'
require 'json'

module Fastlane
  module Actions
    class OpenaiAskAction < Action
      OPENAI_API_ENDPOINT = URI('https://api.openai.com/v1/chat/completions').freeze
      DEFAULT_MAX_TOOL_ITERATIONS = 5
      DEFAULT_MODEL = 'gpt-4o'

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
        model = params[:model] || DEFAULT_MODEL
        tools = params[:tools]
        # Tool names from the OpenAI API are always JSON strings. Normalize handler keys so
        # callers can register handlers with either string or symbol keys without surprises.
        tool_handlers = (params[:tool_handlers] || {}).transform_keys(&:to_s)
        max_tool_iterations = params[:max_tool_iterations] || DEFAULT_MAX_TOOL_ITERATIONS

        headers = {
          'Content-Type': 'application/json',
          Authorization: "Bearer #{api_token}"
        }

        # Backwards-compatible single-shot path when no tools are provided.
        if tools.nil? || tools.empty?
          body = request_body(prompt: prompt, question: question, model: model)
          response = Net::HTTP.post(OPENAI_API_ENDPOINT, body, headers)
          return parse_text_response(response)
        end

        run_with_tools(
          prompt: prompt,
          question: question,
          model: model,
          tools: tools,
          tool_handlers: tool_handlers,
          max_tool_iterations: max_tool_iterations,
          headers: headers
        )
      end

      def self.run_with_tools(prompt:, question:, model:, tools:, tool_handlers:, max_tool_iterations:, headers:)
        messages = [
          format_message(role: 'system', text: prompt),
          format_message(role: 'user', text: question),
        ].compact

        max_tool_iterations.times do
          body = request_body_with_messages(messages: messages, tools: tools, model: model)
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

      def self.request_body(prompt:, question:, model: DEFAULT_MODEL)
        {
          model: model,
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

      def self.request_body_with_messages(messages:, tools:, model: DEFAULT_MODEL)
        {
          model: model,
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
        result = invoke_tool_handler(name: name, handler: handler, args: args)

        {
          role: 'tool',
          tool_call_id: tool_call['id'],
          content: result.to_json
        }
      end

      # Invokes a tool handler safely. Returns a JSON-serializable Hash that will be
      # sent back to the model as the `content` of a `role: tool` message.
      #
      # - Missing handler: structured `{ error: ... }` so the model can recover.
      # - Handler raised: structured `{ error:, exception:, message: }` so the model can
      #   see the failure and adjust. The loop keeps going rather than aborting the lane
      #   mid-conversation — the model is the better judge of whether the failure is
      #   recoverable than a global `rescue` here.
      def self.invoke_tool_handler(name:, handler:, args:)
        return { error: "No handler defined for tool '#{name}'" } if handler.nil?
        return { error: "Handler for tool '#{name}' is not callable (got #{handler.class})" } unless handler.respond_to?(:call)

        begin
          handler.call(args)
        rescue StandardError => e
          { error: "Handler for tool '#{name}' raised", exception: e.class.name, message: e.message }
        end
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
          <<~'EXAMPLE',
            items = extract_release_notes_for_version(version: app_version, release_notes_file_path: 'RELEASE-NOTES.txt')
            nice_changelog = openai_ask(
              prompt: :release_notes, # Uses the pre-crafted prompt for App Store / Play Store release notes
              question: "Help me write release notes for the following items:\n#{items}",
              api_token: get_required_env('OPENAI_API_TOKEN')
            )
            File.write(File.join('fastlane', 'metadata', 'android', 'en-US', 'changelogs', 'default.txt'), nice_changelog)
          EXAMPLE
          <<~'EXAMPLE',
            # Tool-use loop: the model proposes release notes via a tool call; the handler validates
            # length locally and rejects until the model produces text under the limit.
            notes = openai_ask(
              prompt: :release_notes,
              question: "Write release notes for: #{items}. Call the validate_length tool with your draft and iterate until it accepts.",
              api_token: get_required_env('OPENAI_API_TOKEN'),
              tools: [{
                type: 'function',
                function: {
                  name: 'validate_length',
                  description: 'Validates the length of the proposed release notes against a 350-character budget. ' \
                               'Returns `{ ok: true, length: }` if the text fits, or `{ ok: false, length:, max: }` otherwise. ' \
                               'Call repeatedly with shorter drafts until it returns ok: true.',
                  parameters: {
                    type: 'object',
                    properties: { text: { type: 'string' } },
                    required: ['text']
                  }
                }
              }],
              tool_handlers: {
                'validate_length' => ->(args) {
                  len = args['text'].length
                  len <= 350 ? { ok: true, length: len } : { ok: false, length: len, max: 350 }
                }
              }
            )
          EXAMPLE
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
          FastlaneCore::ConfigItem.new(key: :model,
                                       description: 'The OpenAI model to send the request to (e.g. `gpt-4o`, `gpt-4o-mini`, `gpt-4.1`). ' \
                                                    "Defaults to `#{DEFAULT_MODEL}`",
                                       optional: true,
                                       default_value: DEFAULT_MODEL,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :tools,
                                       description: 'Optional array of tool (function-calling) definitions in OpenAI format. ' \
                                                    'When provided, the action runs a tool-use loop',
                                       optional: true,
                                       default_value: nil,
                                       type: Array,
                                       verify_block: proc do |value|
                                         UI.user_error!('Parameter `tools` must be a non-empty Array when provided') if value.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :tool_handlers,
                                       description: 'Hash of tool name to a callable (e.g. a Proc) invoked when the model calls that tool. ' \
                                                    'The callable receives the parsed arguments Hash and must return a JSON-serializable value, ' \
                                                    'which is sent back to the model as the tool result',
                                       optional: true,
                                       default_value: nil,
                                       type: Hash,
                                       verify_block: proc do |value|
                                         non_callable = value.reject { |_k, v| v.respond_to?(:call) }
                                         UI.user_error!("Parameter `tool_handlers` values must respond to :call. Non-callable handlers: #{non_callable.keys}") if non_callable.any?
                                       end),
          FastlaneCore::ConfigItem.new(key: :max_tool_iterations,
                                       description: 'Maximum number of tool-use loop iterations before the action fails. ' \
                                                    'Only used when `tools` are provided',
                                       optional: true,
                                       default_value: DEFAULT_MAX_TOOL_ITERATIONS,
                                       type: Integer,
                                       verify_block: proc do |value|
                                         UI.user_error!("Parameter `max_tool_iterations` must be >= 1 (got #{value})") if value < 1
                                       end),
        ]
      end

      def self.is_supported?(_platform)
        true
      end
    end
  end
end
