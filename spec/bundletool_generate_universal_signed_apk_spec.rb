require 'spec_helper'

describe Fastlane::Actions::BundletoolGenerateUniversalSignedApkAction do
  let(:aab_path) { 'path/to/app.aab' }
  let(:apk_output_path) { 'path/to/output' }
  let(:keystore_path) { 'path/to/keystore' }
  let(:keystore_password) { 'keystore_password' }
  let(:keystore_key_alias) { 'keystore_key_alias' }
  let(:signing_key_password) { 'signing_key_password' }

  describe 'bundletool_generate_universal_signed_apk' do
    it 'calls the `bundletool` command with the correct arguments' do
      cmd = run_described_fastlane_action(
        aab_path: aab_path,
        apk_output_path: apk_output_path,
        keystore_path: keystore_path,
        keystore_password: keystore_password,
        keystore_key_alias: keystore_key_alias,
        signing_key_password: signing_key_password
      )
      expect(cmd).to eq("bundletool build-apks --mode universal --bundle #{aab_path} --output-format DIRECTORY --output #{apk_output_path} --ks #{keystore_path} --ks-pass #{keystore_password} --ks-key-alias #{keystore_key_alias} --key-pass #{signing_key_password}")
    end
  end
end
