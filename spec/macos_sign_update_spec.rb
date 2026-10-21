# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::MacosSignUpdateAction do
  let(:archive_path) { File.expand_path('App with spaces.zip') }
  let(:archive_content) { 'final notarized archive' }
  let(:signing_tool) { RbConfig.ruby }
  let(:key_pair) { OpenSSL::PKey.generate_key('ED25519') }
  let(:private_key) { Base64.strict_encode64(key_pair.private_to_der[-32..]) }
  let(:public_key) { Base64.strict_encode64(key_pair.public_to_der[-32..]) }
  let(:signature) { Base64.strict_encode64(key_pair.sign(nil, archive_content)) }
  let(:params) { { archive_path: archive_path, signing_tool: signing_tool, private_key: private_key, public_key: public_key } }
  let(:tool_output) { "#{signature}\n" }
  let(:status) { instance_double(Process::Status, success?: true) }

  around do |example|
    in_tmp_dir do
      File.write(archive_path, archive_content)
      example.run
    end
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('SPARKLE_PRIVATE_KEY').and_return(nil)
  end

  def expect_signing(output: tool_output, stderr: '', input_key: private_key)
    allow(Open3).to receive(:capture3).and_return([output, stderr, status])
    expect(Open3).to receive(:capture3).with(
      { 'SPARKLE_PRIVATE_KEY' => nil }, signing_tool, '-p', '--ed-key-file', '-', archive_path,
      stdin_data: "#{input_key}\n"
    )
  end

  it 'passes the key only through stdin and returns the verified signature' do
    expect_signing
    expect(run_described_fastlane_action(params)).to eq(signature)
  end

  it 'loads the sensitive key from SPARKLE_PRIVATE_KEY' do
    allow(ENV).to receive(:[]).with('SPARKLE_PRIVATE_KEY').and_return(private_key)
    expect_signing
    expect(run_described_fastlane_action(params.except(:private_key))).to eq(signature)
    expect(described_class.available_options.find { |option| option.key == :private_key }.sensitive).to be(true)
  end

  it 'accepts exported legacy keys' do
    legacy_key = Base64.strict_encode64('k' * 96)
    expect_signing(input_key: legacy_key)
    expect(run_described_fastlane_action(params.merge(private_key: legacy_key))).to eq(signature)
  end

  it 'accepts a trailing newline on an exported private key' do
    expect_signing
    expect(run_described_fastlane_action(params.merge(private_key: "#{private_key}\n"))).to eq(signature)
  end

  [nil, '', '  '].each do |key|
    it "fails without invoking the tool when the key is #{key.inspect}" do
      expect(Open3).not_to receive(:capture3)
      expect { run_described_fastlane_action(params.merge(private_key: key)) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /A Sparkle private key is required/)
    end
  end

  ['invalid-private-key', Base64.strict_encode64('k' * 64), "#{'A' * 42}B="].each do |key|
    it "rejects an invalid key of #{key.length} characters without logging it" do
      expect(Open3).not_to receive(:capture3)
      expect(FastlaneCore::UI).not_to receive(:error).with(include(key))
      expect { run_described_fastlane_action(params.merge(private_key: key)) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, 'Sparkle private key must be base64 for a 32-byte seed or a 96-byte legacy key')
    end
  end

  it 'fails on tool errors without printing captured output that may contain the key' do
    allow(status).to receive(:success?).and_return(false)
    expect_signing(output: "Invalid key: #{private_key}", stderr: private_key)
    expect(FastlaneCore::UI).not_to receive(:error).with(include(private_key))
    expect(FastlaneCore::UI).not_to receive(:message).with(include(private_key))
    expect { run_described_fastlane_action(params) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, 'Sparkle sign_update failed; check the signing tool and private key')
  end

  it 'reports process errors without their potentially sensitive details' do
    expect(Open3).to receive(:capture3).and_raise(Errno::EACCES, private_key)
    expect { run_described_fastlane_action(params) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, 'Unable to run Sparkle sign_update or read the archive') do |error|
        expect(error.full_message).not_to include(private_key)
      end
  end

  it 'rejects unexpected output without printing it' do
    expect_signing(output: "unexpected #{private_key}")
    expect { run_described_fastlane_action(params) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, 'EdDSA signature must be canonical base64 for exactly 64 bytes')
  end

  it 'rejects malformed signatures returned by the tool' do
    expect_signing(output: 'invalid')
    expect { run_described_fastlane_action(params) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, 'EdDSA signature must be canonical base64 for exactly 64 bytes')
  end

  it 'rejects a signature made by a different key than the app trusts' do
    other_public_key = Base64.strict_encode64(OpenSSL::PKey.generate_key('ED25519').public_to_der[-32..])
    expect_signing
    expect { run_described_fastlane_action(params.merge(public_key: other_public_key)) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, 'Sparkle signature does not verify against the app public key and archive')
  end

  it 'rejects archive changes that preserve the file length' do
    expect(Open3).to receive(:capture3) do
      File.write(archive_path, 'x' * archive_content.bytesize)
      [tool_output, '', status]
    end
    expect { run_described_fastlane_action(params) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, 'Sparkle signature does not verify against the app public key and archive')
  end

  it 'rejects an invalid app public key before invoking the tool' do
    expect(Open3).not_to receive(:capture3)
    expect { run_described_fastlane_action(params.merge(public_key: 'invalid')) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, 'Sparkle public key must be canonical base64 for exactly 32 bytes')
  end

  it 'rejects a missing archive' do
    expect { run_described_fastlane_action(params.merge(archive_path: 'missing.zip')) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, "Archive not found at 'missing.zip'")
  end

  it 'rejects a signing tool that is not executable' do
    expect { run_described_fastlane_action(params.merge(signing_tool: archive_path)) }
      .to raise_error(FastlaneCore::Interface::FastlaneError, /Sparkle signing tool is not executable/)
  end
end
