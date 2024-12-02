require 'fastlane/action'
require 'net/http'
require 'json'

module Fastlane
  module Actions
    class OpenaiGenerateAction < Action
      OPENAI_API_ENDPOINT = URI('https://api.openai.com/v1/chat/completions').freeze

      RELEASE_NOTES_PROMPT = <<~PROMPT.freeze
        Act like a mobile app marketer who wants to prepare release notes for Google Play and App Store.
        Do not write it point by point and keep it under 350 characters. It should be a unique paragraph.

        When provided a list, use the number of any potential "*" in brackets at the start of each item as indicator of importance.
        Ignore items starting with "[Internal]", and ignore links to GitHub.
      PROMPT

      def self.run(params)
        api_token = params[:api_token]
        prompt = params[:prompt]
        prompt = RELEASE_NOTES_PROMPT if prompt == ':release_notes'
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
          best_choice = json['choices']&.first
          UI.abort_with_message!("Unable to parse OpenAPI response\n#{json}") if best_choice.nil?
          best_choice['message']['content']
        else
          UI.user_error!("Error in OpenAPI API response: #{response}. #{response.body}")
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

      def self.description
        'Use OpenAI API to generate response to a prompt'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'The response from the prompt as returned by OpenAI API'
      end

      def self.details
        <<~DETAILS
          Uses the OpenAPI API to generate response to a prompt.
          Can be used to e.g. ask it to generate Release Notes based on a bullet point technical changelog or similar.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :prompt,
                                       description: 'The internal top-level instructions to give to the model to tell it how to behave. Use `:release_notes` to use a predefined prompt to ask to write release notes from a changelog list',
                                       optional: true,
                                       default_value: nil,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :question,
                                       description: 'The user message to ask the question to the OpenAI model',
                                       optional: false,
                                       default_value: nil,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       description: 'The OpenAPI API Token to use for the request',
                                       env_name: 'OPENAPI_API_TOKEN',
                                       optional: false,
                                       sensitive: true,
                                       type: String),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
