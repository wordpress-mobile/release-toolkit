require 'fastlane/action'
require 'net/http'
require 'json'

module Fastlane
  module Actions
    class OpenaiGenerateAction < Action
      OPENAI_API_ENDPOINT = URI('https://api.openai.com/v1/chat/completions').freeze

      PREDEFINED_PROMPTS = {
        release_notes: <<~PROMPT.freeze
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

        headers = {
          'Content-Type': 'application/json',
          Authorization: "Bearer #{api_token}"
        }
        body = request_body(prompt: prompt, question: question)

        response = Net::HTTP.post(OPENAI_API_ENDPOINT, body, headers)

        case response
        when Net::HTTPOK
          json = JSON.parse(response.body)
          json['choices']&.first&.dig('message', 'content')
        else
          UI.user_error!("Error in OpenAI API response: #{response}. #{response.body}")
        end
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

      def self.format_message(role:, text:)
        return nil if text.nil? || text.empty?

        {
          role: role,
          content: [{ type: 'text', text: text }]
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
        'The response text from the prompt as returned by OpenAI API'
      end

      def self.details
        <<~DETAILS
          Uses the OpenAI API to generate response to a prompt.
          Can be used to e.g. ask it to generate Release Notes based on a bullet point technical changelog or similar.
        DETAILS
      end

      def self.examples
        [
          <<~EXEMPLE,
            items = extract_release_notes_for_version(version: app_version, release_notes_file_path: 'RELEASE-NOTES.txt')
            nice_changelog = openai_generate(
              prompt: :release_notes, # Uses the pre-crafted prompt for App Store / Play Store release notes
              question: "Help me write release notes for the following items:\n#{items}",
              api_token: get_required_env('OPENAI_API_TOKEN')
            )
            File.write(File.join('fastlane', 'metadata', 'android', en-US', 'changelogs', 'default.txt'), nice_changelog)
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
        ]
      end

      def self.is_supported?(_platform)
        true
      end
    end
  end
end
