require 'spec_helper.rb'

describe Fastlane::Helper::EncryptionHelper do
  let(:cipher) { double('cipher') }

  before(:each) do
    allow(OpenSSL::Cipher::AES256).to receive(:new).with(:CBC).and_return(cipher)
  end

  it 'encrypts the input' do
    expect(cipher).to receive(:encrypt)
    expect(cipher).to receive(:key=).with('key')

    expect(cipher).to receive(:update).with('plain text').and_return('encrypted')
    expect(cipher).to receive(:final).and_return('!')

    expect(Fastlane::Helper::EncryptionHelper.encrypt('plain text', 'key')).to eq('encrypted!')
  end

  it 'decrypts the input' do
    expect(cipher).to receive(:decrypt)
    expect(cipher).to receive(:key=).with('key')

    expect(cipher).to receive(:update).with('encrypted').and_return('plain text')
    expect(cipher).to receive(:final).and_return('!')

    expect(Fastlane::Helper::EncryptionHelper.decrypt('encrypted', 'key')).to eq('plain text!')
  end

  it 'generates a random key' do
    expect(cipher).to receive(:encrypt)
    expect(cipher).to receive(:random_key).and_return('random key')

    expect(Fastlane::Helper::EncryptionHelper.generate_key).to eq('random key')
  end
end
