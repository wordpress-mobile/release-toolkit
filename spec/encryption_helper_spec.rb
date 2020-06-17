require 'spec_helper.rb'
require 'securerandom'

describe Fastlane::Helper::EncryptionHelper do

  it 'can encrypt and decrypt data' do
    string = SecureRandom.hex
    key = Fastlane::Helper::EncryptionHelper.generate_key
    encrypted = Fastlane::Helper::EncryptionHelper.encrypt(string, key)
    decrypted = Fastlane::Helper::EncryptionHelper.decrypt(encrypted, key)
    expect(string).to eq decrypted
  end

  it 'generates a random key that is 32 bytes long' do
    expect(Fastlane::Helper::EncryptionHelper.generate_key.length).to eq(32)
  end
end
