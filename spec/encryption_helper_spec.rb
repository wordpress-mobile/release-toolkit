require 'spec_helper'

describe Fastlane::Helper::EncryptionHelper do
  let(:cipher) { double('cipher') }

  before(:each) do
    allow(OpenSSL::Cipher).to receive(:new).with('aes-256-cbc').and_return(cipher)
  end

  it 'encrypts the input' do
    expect(cipher).to receive(:encrypt)
    expect(cipher).to receive(:key=).with('key')

    expect(cipher).to receive(:update).with('plain text').and_return('encrypted')
    expect(cipher).to receive(:final).and_return('!')

    expect(described_class.encrypt('plain text', 'key')).to eq('encrypted!')
  end

  it 'decrypts the input' do
    expect(cipher).to receive(:decrypt)
    expect(cipher).to receive(:key=).with('key')

    expect(cipher).to receive(:update).with('encrypted').and_return('plain text')
    expect(cipher).to receive(:final).and_return('!')

    expect(described_class.decrypt('encrypted', 'key')).to eq('plain text!')
  end

  it 'generates a random key' do
    expect(cipher).to receive(:encrypt)
    expect(cipher).to receive(:random_key).and_return('random key')

    expect(described_class.generate_key).to eq('random key')
  end
end
