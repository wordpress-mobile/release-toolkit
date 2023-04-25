require 'spec_helper'

describe Fastlane::Actions::AndroidGenerateApkFromAabAction do
  before do
    allow(File).to receive(:file?).with(aab_file_path).and_return('mocked file data')
    allow(File).to receive(:file?).with(apk_output_file_path).and_return('mocked file data')
    allow(File).to receive(:file?).with(keystore_path).and_return('mocked file data')
  end

  let(:aab_file_path) { 'path/to/app.aab' }
  let(:apk_output_file_path) { 'path/to/app.apk' }
  let(:keystore_path) { 'path/to/keystore' }
  let(:keystore_password) { 'keystore_password' }
  let(:keystore_key_alias) { 'keystore_key_alias' }
  let(:signing_key_password) { 'signing_key_password' }

  def generate_command(apk_output_file_path:, aab_file_path: nil, keystore_path: nil, keystore_password: nil, keystore_key_alias: nil, signing_key_password: nil)
    command = "bundletool build-apks --mode universal --bundle #{aab_file_path} --output-format DIRECTORY --output #{apk_output_file_path} "
    code_sign_arguments = "--ks #{keystore_path} --ks-pass #{keystore_password} --ks-key-alias #{keystore_key_alias} --key-pass #{signing_key_password} "
    move_and_cleanup_command = "&& mv #{apk_output_file_path}/universal.apk #{apk_output_file_path}_tmp && rm -rf #{apk_output_file_path} && mv #{apk_output_file_path}_tmp #{apk_output_file_path}"

    # Append the code signing arguments
    command += code_sign_arguments unless keystore_path.nil?

    # Append the move and cleanup command
    command += move_and_cleanup_command
    return command
  end

  describe 'android_generate_apk_from_aab' do
    it 'calls the `bundletool` command with the correct arguments when generating a signed APK' do
      cmd = run_described_fastlane_action(
        aab_file_path: aab_file_path,
        apk_output_file_path: apk_output_file_path,
        keystore_path: keystore_path,
        keystore_password: keystore_password,
        keystore_key_alias: keystore_key_alias,
        signing_key_password: signing_key_password
      )
      expected_command = generate_command(aab_file_path: aab_file_path,
                                          apk_output_file_path: apk_output_file_path,
                                          keystore_path: keystore_path,
                                          keystore_password: keystore_password,
                                          keystore_key_alias: keystore_key_alias,
                                          signing_key_password: signing_key_password)
      expect(cmd).to eq(expected_command)
    end

    it 'calls the `bundletool` command with the correct arguments when generating an unsigned APK' do
      cmd = run_described_fastlane_action(
        aab_file_path: aab_file_path,
        apk_output_file_path: apk_output_file_path
      )
      expected_command = generate_command(aab_file_path: aab_file_path,
                                          apk_output_file_path: apk_output_file_path)
      expect(cmd).to eq(expected_command)
    end

    it 'calls the `bundletool` command with the correct arguments and use the path to the AAB from the lane context if the SharedValues::GRADLE_AAB_OUTPUT_PATH key is set' do
      aab_path_from_context = 'path/from/context/app.aab'

      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::GRADLE_AAB_OUTPUT_PATH] = aab_path_from_context

      cmd = run_described_fastlane_action(
        apk_output_file_path: apk_output_file_path
      )

      expected_command = generate_command(aab_file_path: aab_path_from_context,
                                          apk_output_file_path: apk_output_file_path)
      expect(cmd).to eq(expected_command)
    end

    it 'calls the `bundletool` command with the correct arguments and use the path to the AAB from the lane context if the SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS key is set' do
      all_aab_paths_from_context = ['first/path/from/context/app.aab']

      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS] = all_aab_paths_from_context

      cmd = run_described_fastlane_action(
        apk_output_file_path: apk_output_file_path
      )

      expected_command = generate_command(aab_file_path: all_aab_paths_from_context.first,
                                          apk_output_file_path: apk_output_file_path)
      expect(cmd).to eq(expected_command)
    end
  end
end
