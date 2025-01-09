# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::OpenaiAskAction do
  let(:fake_token) { 'sk-proj-faketok' }
  let(:endpoint) { Fastlane::Actions::OpenaiAskAction::OPENAI_API_ENDPOINT }

  def stubbed_response(text)
    <<~JSON
      {
        "id": "chatcmpl-Aa2NPY4sSWF5eKoW1aFBJmfc78y9p",
        "object": "chat.completion",
        "created": 1733152307,
        "model": "gpt-4o-2024-08-06",
        "choices": [
          {
            "index": 0,
            "message": {
              "role": "assistant",
              "content": #{text.to_json},
              "refusal": null
            },
            "logprobs": null,
            "finish_reason": "stop"
          }
        ],
        "usage": {
          "prompt_tokens": 91,
          "completion_tokens": 68,
          "total_tokens": 159,
          "prompt_tokens_details": {
            "cached_tokens": 0,
            "audio_tokens": 0
          },
          "completion_tokens_details": {
            "reasoning_tokens": 0,
            "audio_tokens": 0,
            "accepted_prediction_tokens": 0,
            "rejected_prediction_tokens": 0
          }
        },
        "system_fingerprint": "fp_831e067d82"
      }
    JSON
  end

  def run_test(prompt_param:, question_param:, expected_prompt:, expected_response:)
    expected_req_body = described_class.request_body(prompt: expected_prompt, question: question_param)

    stub = stub_request(:post, endpoint)
           .with(body: expected_req_body)
           .to_return(status: 200, body: stubbed_response(expected_response))

    result = run_described_fastlane_action(
      api_token: fake_token,
      prompt: prompt_param,
      question: question_param
    )

    # Ensure the body of the request contains the expected JSON data
    messages = JSON.parse(expected_req_body)['messages']
    if expected_prompt.nil? || expected_prompt.empty?
      expect(messages.length).to eq(1)
      expect(messages[0]['role']).to eq('user')
      expect(messages[0]['content']).to eq(['type' => 'text', 'text' => question_param])
    else
      expect(messages.length).to eq(2)
      expect(messages[0]['role']).to eq('system')
      expect(messages[0]['content']).to eq(['type' => 'text', 'text' => expected_prompt])
      expect(messages[1]['role']).to eq('user')
      expect(messages[1]['content']).to eq(['type' => 'text', 'text' => question_param])
    end

    # Ensure the request has been made and return the action response for it to be validated in calling test
    expect(stub).to have_been_requested
    result
  end

  it 'calls the API with no prompt' do
    result = run_test(
      prompt_param: '',
      question_param: 'Say Hi',
      expected_prompt: nil,
      expected_response: 'Hello! How can I assist you today?'
    )

    expect(result).to eq('Hello! How can I assist you today?')
  end

  it 'calls the API with :release_notes prompt' do
    changelog = <<~CHANGELOG
      - [Internal] Fetch remote FF on site change [https://github.com/woocommerce/woocommerce-android/pull/12751]
      - [**] Improve barcode scanner reading accuracy [https://github.com/woocommerce/woocommerce-android/pull/12673]
      - [Internal] AI product creation banner is removed [https://github.com/woocommerce/woocommerce-android/pull/12705]
      - [*] [Login] Fix an issue where the app doesn't show the correct error screen when application passwords are disabled [https://github.com/woocommerce/woocommerce-android/pull/12717]
      - [**] Fixed bug with coupons disappearing from the order creation screen unexpectedly [https://github.com/woocommerce/woocommerce-android/pull/12724]
      - [Internal] Fixes crash [https://github.com/woocommerce/woocommerce-android/issues/12715]
      - [*] Fixed incorrect instructions on "What is Tap to Pay" screen in the Payments section [https://github.com/woocommerce/woocommerce-android/pull/12709]
      - [***] Merchants can now view and edit custom fields of their products and orders from the app [https://github.com/woocommerce/woocommerce-android/issues/12207]
      - [*] Fix size of the whats new announcement dialog [https://github.com/woocommerce/woocommerce-android/pull/12692]
      - [*] Enables Blaze survey [https://github.com/woocommerce/woocommerce-android/pull/12761]
    CHANGELOG

    expected_response = <<~TEXT
      Exciting updates are here! We've enhanced the barcode scanner for optimal accuracy and resolved the issue with coupons vanishing during order creation. Most significantly, merchants can now effortlessly view and edit custom fields for products and orders directly within the app. Additionally, we've improved error handling on login and fixed various UI inconsistencies. Enjoy a smoother experience!
    TEXT

    result = run_test(
      prompt_param: :release_notes,
      question_param: "Help me write release notes for the following items:\n#{changelog}",
      expected_prompt: Fastlane::Actions::OpenaiAskAction::PREDEFINED_PROMPTS[:release_notes],
      expected_response: expected_response
    )

    expect(result).to eq(expected_response)
  end
end
