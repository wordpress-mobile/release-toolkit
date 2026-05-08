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

  # Stubbed response in which the assistant invokes a single tool call.
  def stubbed_tool_call_response(tool_call_id:, name:, arguments_json:)
    {
      id: 'chatcmpl-toolcall',
      object: 'chat.completion',
      created: 1_733_152_308,
      model: 'gpt-4o-2024-08-06',
      choices: [
        {
          index: 0,
          message: {
            role: 'assistant',
            content: nil,
            tool_calls: [
              {
                id: tool_call_id,
                type: 'function',
                function: { name: name, arguments: arguments_json }
              }
            ]
          },
          logprobs: nil,
          finish_reason: 'tool_calls'
        }
      ]
    }.to_json
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
      expect(messages[0]['content']).to eq([{ 'type' => 'text', 'text' => question_param }])
    else
      expect(messages.length).to eq(2)
      expect(messages[0]['role']).to eq('system')
      expect(messages[0]['content']).to eq([{ 'type' => 'text', 'text' => expected_prompt }])
      expect(messages[1]['role']).to eq('user')
      expect(messages[1]['content']).to eq([{ 'type' => 'text', 'text' => question_param }])
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

  describe 'with tool-use' do
    # Tool-use specs invoke `described_class.run` directly rather than
    # `run_described_fastlane_action`, because the latter inspects parameters
    # into an eval'd Fastlane lane — and `Proc#inspect` is not valid Ruby.
    let(:tools) do
      [
        {
          type: 'function',
          function: {
            name: 'check_length',
            description: 'Validates the proposed text against a length budget.',
            parameters: {
              type: 'object',
              properties: { text: { type: 'string' } },
              required: ['text']
            }
          }
        }
      ]
    end

    it 'invokes a tool handler and feeds the result back to the model' do
      handler_calls = []
      tool_handlers = {
        'check_length' => lambda do |args|
          handler_calls << args
          length = args['text'].length
          length <= 10 ? { ok: true, length: length } : { ok: false, length: length, max: 10 }
        end
      }

      # First turn: model calls check_length with text that is too long.
      first_response = stubbed_tool_call_response(
        tool_call_id: 'call_1',
        name: 'check_length',
        arguments_json: { text: 'this is way too long' }.to_json
      )

      # Second turn: model produces a final text answer (no tool call).
      second_response = stubbed_response('Final answer.')

      stub = stub_request(:post, endpoint)
             .to_return(
               { status: 200, body: first_response },
               { status: 200, body: second_response }
             )

      result = described_class.run(
        api_token: fake_token,
        prompt: 'You are a helpful assistant.',
        question: 'Write something short.',
        tools: tools,
        tool_handlers: tool_handlers
      )

      expect(result).to eq('Final answer.')
      expect(stub).to have_been_requested.twice
      expect(handler_calls).to eq([{ 'text' => 'this is way too long' }])
    end

    it 'sends previous turn messages including the tool result on the second request' do
      tool_handlers = {
        'check_length' => ->(_args) { { ok: false, message: 'too long' } }
      }

      first_response = stubbed_tool_call_response(
        tool_call_id: 'call_xyz',
        name: 'check_length',
        arguments_json: { text: 'draft' }.to_json
      )
      second_response = stubbed_response('Shorter draft.')

      recorded_bodies = []
      stub_request(:post, endpoint)
        .with { |req| recorded_bodies << req.body }
        .to_return(
          { status: 200, body: first_response },
          { status: 200, body: second_response }
        )

      described_class.run(
        api_token: fake_token,
        prompt: 'sys',
        question: 'q',
        tools: tools,
        tool_handlers: tool_handlers
      )

      # Inspect the second POST body: it should include the assistant tool_call message
      # and the tool result message keyed by tool_call_id.
      body = JSON.parse(recorded_bodies.last)
      messages = body['messages']

      assistant_tool_call_msg = messages.find { |m| m['role'] == 'assistant' && m['tool_calls'] }
      tool_result_msg = messages.find { |m| m['role'] == 'tool' }

      expect(assistant_tool_call_msg).not_to be_nil
      expect(assistant_tool_call_msg['tool_calls'].first['id']).to eq('call_xyz')
      expect(tool_result_msg).not_to be_nil
      expect(tool_result_msg['tool_call_id']).to eq('call_xyz')
      expect(JSON.parse(tool_result_msg['content'])).to eq({ 'ok' => false, 'message' => 'too long' })
      expect(body['tools']).to eq(JSON.parse(tools.to_json))
    end

    it 'fails when the loop exceeds max_tool_iterations' do
      tool_handlers = {
        'check_length' => ->(_args) { { ok: false } }
      }

      # Always return a tool call — the loop should never terminate naturally.
      perpetual_tool_call = stubbed_tool_call_response(
        tool_call_id: 'call_loop',
        name: 'check_length',
        arguments_json: { text: 'x' }.to_json
      )
      stub_request(:post, endpoint)
        .to_return(status: 200, body: perpetual_tool_call)

      expect do
        described_class.run(
          api_token: fake_token,
          prompt: 'sys',
          question: 'q',
          tools: tools,
          tool_handlers: tool_handlers,
          max_tool_iterations: 2
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /did not terminate after 2 iterations/)
    end

    it 'returns an error tool result when no handler is registered for the called tool' do
      first_response = stubbed_tool_call_response(
        tool_call_id: 'call_unknown',
        name: 'unregistered_tool',
        arguments_json: '{}'
      )
      second_response = stubbed_response('Recovered.')

      recorded_bodies = []
      stub_request(:post, endpoint)
        .with { |req| recorded_bodies << req.body }
        .to_return(
          { status: 200, body: first_response },
          { status: 200, body: second_response }
        )

      result = described_class.run(
        api_token: fake_token,
        prompt: 'sys',
        question: 'q',
        tools: tools,
        tool_handlers: {}
      )

      expect(result).to eq('Recovered.')

      messages = JSON.parse(recorded_bodies.last)['messages']
      tool_result_msg = messages.find { |m| m['role'] == 'tool' }
      expect(JSON.parse(tool_result_msg['content'])).to eq(
        { 'error' => "No handler defined for tool 'unregistered_tool'" }
      )
    end
  end
end
