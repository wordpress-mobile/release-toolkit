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
              },
            ]
          },
          logprobs: nil,
          finish_reason: 'tool_calls'
        },
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

  it 'sends the configured model on the wire when overridden (single-shot path)' do
    expected_req_body = described_class.request_body(prompt: 'sys', question: 'q', model: 'gpt-4o-mini')

    stub = stub_request(:post, endpoint)
           .with(body: expected_req_body)
           .to_return(status: 200, body: stubbed_response('Hi.'))

    run_described_fastlane_action(
      api_token: fake_token,
      prompt: 'sys',
      question: 'q',
      model: 'gpt-4o-mini'
    )

    expect(stub).to have_been_requested
    expect(JSON.parse(expected_req_body)['model']).to eq('gpt-4o-mini')
  end

  it 'uses max_completion_tokens instead of deprecated max_tokens' do
    body = JSON.parse(described_class.request_body(prompt: 'sys', question: 'q'))

    expect(body['max_completion_tokens']).to eq(described_class.const_get(:DEFAULT_MAX_COMPLETION_TOKENS))
    expect(body).not_to have_key('max_tokens')
  end

  it 'opts out of storing Chat Completions by default' do
    body = JSON.parse(described_class.request_body(prompt: 'sys', question: 'q'))

    expect(body['store']).to eq(false)
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
        },
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
      expect(body['store']).to eq(false)
      expect(body['max_completion_tokens']).to eq(described_class.const_get(:DEFAULT_MAX_COMPLETION_TOKENS))
      expect(body).not_to have_key('max_tokens')
    end

    it 'fails when the loop exceeds max_tool_iterations' do
      handler_calls = []
      tool_handlers = {
        'check_length' => lambda do |args|
          handler_calls << args
          { ok: false }
        end
      }

      # Always return tool calls; the third one must not be executed when the cap is 2.
      first_tool_call = stubbed_tool_call_response(
        tool_call_id: 'call_loop_1',
        name: 'check_length',
        arguments_json: { text: 'first' }.to_json
      )
      second_tool_call = stubbed_tool_call_response(
        tool_call_id: 'call_loop_2',
        name: 'check_length',
        arguments_json: { text: 'second' }.to_json
      )
      third_tool_call = stubbed_tool_call_response(
        tool_call_id: 'call_loop_3',
        name: 'check_length',
        arguments_json: { text: 'third' }.to_json
      )
      stub = stub_request(:post, endpoint)
             .to_return(
               { status: 200, body: first_tool_call },
               { status: 200, body: second_tool_call },
               { status: 200, body: third_tool_call }
             )

      expect do
        described_class.run(
          api_token: fake_token,
          prompt: 'sys',
          question: 'q',
          tools: tools,
          tool_handlers: tool_handlers,
          max_tool_iterations: 2
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /did not produce a final answer after 2 tool iterations/)

      expect(stub).to have_been_requested.times(3)
      expect(handler_calls).to eq([{ 'text' => 'first' }, { 'text' => 'second' }])
    end

    it 'allows one final model response after the last permitted tool iteration' do
      handler_calls = []
      tool_handlers = {
        'check_length' => lambda do |args|
          handler_calls << args
          { ok: true }
        end
      }
      first_response = stubbed_tool_call_response(
        tool_call_id: 'call_once',
        name: 'check_length',
        arguments_json: { text: 'draft' }.to_json
      )
      second_response = stubbed_response('Final answer.')

      stub = stub_request(:post, endpoint)
             .to_return(
               { status: 200, body: first_response },
               { status: 200, body: second_response }
             )

      result = described_class.run(
        api_token: fake_token,
        prompt: 'sys',
        question: 'q',
        tools: tools,
        tool_handlers: tool_handlers,
        max_tool_iterations: 1
      )

      expect(result).to eq('Final answer.')
      expect(stub).to have_been_requested.twice
      expect(handler_calls).to eq([{ 'text' => 'draft' }])
    end

    it 'sends the configured model on the wire when overridden' do
      tool_handlers = {
        'check_length' => ->(_args) { { ok: true } }
      }
      first_response = stubbed_response('Done.')

      recorded_bodies = []
      stub_request(:post, endpoint)
        .with { |req| recorded_bodies << req.body }
        .to_return(status: 200, body: first_response)

      described_class.run(
        api_token: fake_token,
        prompt: 'sys',
        question: 'q',
        model: 'gpt-4o-mini',
        tools: tools,
        tool_handlers: tool_handlers
      )

      body = JSON.parse(recorded_bodies.last)
      expect(body['model']).to eq('gpt-4o-mini')
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

    it 'looks up handlers by string key even when registered with symbol keys' do
      tool_handlers = {
        check_length: ->(_args) { { ok: true, source: 'symbol_keyed' } }
      }

      first_response = stubbed_tool_call_response(
        tool_call_id: 'call_sym',
        name: 'check_length',
        arguments_json: { text: 'short' }.to_json
      )
      second_response = stubbed_response('Done.')

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

      tool_result_msg = JSON.parse(recorded_bodies.last)['messages'].find { |m| m['role'] == 'tool' }
      expect(JSON.parse(tool_result_msg['content'])).to eq({ 'ok' => true, 'source' => 'symbol_keyed' })
    end

    it 'returns a structured error tool result when the handler raises' do
      allow(FastlaneCore::Globals).to receive(:verbose?).and_return(true)
      expect(UI).not_to receive(:verbose)

      tool_handlers = {
        'check_length' => ->(_args) { raise ArgumentError, 'bad args' }
      }

      first_response = stubbed_tool_call_response(
        tool_call_id: 'call_raise',
        name: 'check_length',
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

      expect(UI).to receive(:error).with(
        satisfy do |message|
          message.include?("Handler for tool 'check_length' raised ArgumentError") &&
            !message.include?('bad args') &&
            !message.include?("\n")
        end
      )

      result = described_class.run(
        api_token: fake_token,
        prompt: 'sys',
        question: 'q',
        tools: tools,
        tool_handlers: tool_handlers
      )

      expect(result).to eq('Recovered.')

      tool_result_msg = JSON.parse(recorded_bodies.last)['messages'].find { |m| m['role'] == 'tool' }
      content = JSON.parse(tool_result_msg['content'])
      expect(content['error']).to eq("Handler for tool 'check_length' raised an exception")
      expect(content['exception']).to eq('ArgumentError')
      # Exception message must NOT be forwarded to the model — it can carry secrets
      # from the surrounding lane (tokens, file contents, etc.). Only the class name
      # is sent; the full message is also omitted from local logs.
      expect(content).not_to have_key('message')
      expect(tool_result_msg['content']).not_to include('bad args')
    end

    it 'returns a structured error tool result when the handler returns a non-JSON-serializable value' do
      # A class whose `to_json` blows up. Stand-in for a handler accidentally returning
      # a Pathname, Proc, or other object that can't be serialized.
      unserializable_class = Class.new do
        def to_json(*_args)
          raise 'cannot serialize'
        end
      end

      tool_handlers = {
        'check_length' => ->(_args) { unserializable_class.new }
      }

      first_response = stubbed_tool_call_response(
        tool_call_id: 'call_unserializable',
        name: 'check_length',
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

      expect(UI).to receive(:error).with(
        satisfy do |message|
          message.include?("Could not serialize tool result for 'check_length': RuntimeError") &&
            !message.include?('cannot serialize')
        end
      )

      result = described_class.run(
        api_token: fake_token,
        prompt: 'sys',
        question: 'q',
        tools: tools,
        tool_handlers: tool_handlers
      )

      expect(result).to eq('Recovered.')
      tool_result_msg = JSON.parse(recorded_bodies.last)['messages'].find { |m| m['role'] == 'tool' }
      expect(JSON.parse(tool_result_msg['content'])['error']).to match(/could not be serialized to JSON/)
      # Exception message must NOT leak — only the class is acceptable in the structured payload.
      expect(tool_result_msg['content']).not_to include('cannot serialize')
    end

    it 'short-circuits and never invokes the handler when tool arguments are not valid JSON' do
      handler_calls = []
      tool_handlers = {
        'check_length' => lambda do |args|
          handler_calls << args
          { ok: true }
        end
      }

      first_response = stubbed_tool_call_response(
        tool_call_id: 'call_bad_json',
        name: 'check_length',
        arguments_json: 'this is not valid JSON with secret_token=abc123 {'
      )
      second_response = stubbed_response('Recovered.')

      recorded_bodies = []
      stub_request(:post, endpoint)
        .with { |req| recorded_bodies << req.body }
        .to_return(
          { status: 200, body: first_response },
          { status: 200, body: second_response }
        )

      expect(UI).to receive(:error).with(
        satisfy do |message|
          message.include?("Invalid JSON arguments for tool 'check_length'") &&
            !message.include?('secret_token=abc123')
        end
      )

      result = described_class.run(
        api_token: fake_token,
        prompt: 'sys',
        question: 'q',
        tools: tools,
        tool_handlers: tool_handlers
      )

      expect(result).to eq('Recovered.')
      expect(handler_calls).to be_empty
      tool_result_msg = JSON.parse(recorded_bodies.last)['messages'].find { |m| m['role'] == 'tool' }
      expect(JSON.parse(tool_result_msg['content'])['error']).to match(/Invalid JSON arguments.*check_length/)
      expect(tool_result_msg['content']).not_to include('secret_token=abc123')
    end

    it 'does not log raw tool arguments even when verbose mode is enabled' do
      allow(FastlaneCore::Globals).to receive(:verbose?).and_return(true)
      expect(UI).to receive(:error).with(/Raw payload omitted/)
      expect(UI).not_to receive(:verbose)

      result = described_class.execute_tool_call(
        {
          'id' => 'call_bad_json',
          'type' => 'function',
          'function' => {
            'name' => 'check_length',
            'arguments' => 'this is not valid JSON with secret_token=abc123 {',
          },
        },
        {
          'check_length' => ->(_args) { raise 'should not be called' },
        }
      )

      expect(JSON.parse(result[:content])['error']).to match(/Invalid JSON arguments.*check_length/)
      expect(result[:content]).not_to include('secret_token=abc123')
    end

    it 'returns a structured error tool result for unsupported returned tool call types' do
      expect(UI).to receive(:error).with(/Unsupported OpenAI tool call type 'custom'/)

      result = described_class.execute_tool_call(
        {
          'id' => 'call_custom',
          'type' => 'custom',
          'custom' => {
            'name' => 'custom_tool',
            'input' => 'payload',
          },
        },
        {
          'custom_tool' => ->(_args) { raise 'should not be called' },
        }
      )

      expect(result[:role]).to eq('tool')
      expect(result[:tool_call_id]).to eq('call_custom')
      expect(JSON.parse(result[:content])).to eq(
        { 'error' => "Unsupported tool call type 'custom'. Only function tool calls are supported." }
      )
    end

    it 'returns a clear structured error when a returned function tool call has no name' do
      expect(UI).to receive(:error).with(/missing a non-empty function.name/)

      result = described_class.execute_tool_call(
        {
          'id' => 'call_missing_name',
          'type' => 'function',
          'function' => {
            'arguments' => '{}',
          },
        },
        {
          'validate_length' => ->(_args) { raise 'should not be called' },
        }
      )

      expect(result[:role]).to eq('tool')
      expect(result[:tool_call_id]).to eq('call_missing_name')
      expect(JSON.parse(result[:content])).to eq(
        { 'error' => 'Function tool call is missing a non-empty function.name.' }
      )
    end
  end

  describe 'parameter validation' do
    it 'rejects max_tool_iterations < 1' do
      # No `tool_handlers` here — `run_described_fastlane_action` inspects args into an
      # eval'd lane, and `Proc#inspect` is not valid Ruby. The other tool-use specs that
      # need a handler invoke `described_class.run` directly to avoid this. We don't need
      # a handler to exercise the `max_tool_iterations` `verify_block` — it fires before
      # the action body runs.
      expect do
        run_described_fastlane_action(
          api_token: fake_token,
          prompt: 'sys',
          question: 'q',
          tools: [{ type: 'function', function: { name: 'noop', parameters: {} } }],
          max_tool_iterations: 0
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /max_tool_iterations.*must be >= 1/)
    end

    it 'rejects non-integer max_tool_iterations when run directly' do
      expect do
        described_class.run(
          api_token: fake_token,
          prompt: 'sys',
          question: 'q',
          tools: [{ type: 'function', function: { name: 'noop', parameters: {} } }],
          max_tool_iterations: '2'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /max_tool_iterations.*must be an Integer/)
    end

    it 'rejects empty tools array' do
      expect do
        run_described_fastlane_action(
          api_token: fake_token,
          prompt: 'sys',
          question: 'q',
          tools: []
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /tools.*non-empty Array/)
    end

    it 'rejects unsupported tool definition types' do
      expect do
        described_class.run(
          api_token: fake_token,
          prompt: 'sys',
          question: 'q',
          tools: [
            {
              type: 'custom',
              custom: {
                name: 'custom_tool',
              },
            },
          ]
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /only supports OpenAI function tools/)
    end

    it 'rejects function tool definitions without a function name' do
      expect do
        described_class.run(
          api_token: fake_token,
          prompt: 'sys',
          question: 'q',
          tools: [
            {
              type: 'function',
              function: {
                parameters: {},
              },
            },
          ]
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /missing function.name/)
    end

    it 'accepts symbol function names in tool definitions' do
      expect do
        described_class.validate_tools!([{ type: 'function', function: { name: :noop, parameters: {} } }])
      end.not_to raise_error
    end

    it 'rejects tool_handlers with non-callable values' do
      expect do
        run_described_fastlane_action(
          api_token: fake_token,
          prompt: 'sys',
          question: 'q',
          tools: [{ type: 'function', function: { name: 'noop', parameters: {} } }],
          tool_handlers: { 'noop' => 'not_a_proc' }
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /tool_handlers.*must respond to :call/)
    end
  end
end
