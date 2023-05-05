require 'spec_helper'

describe Fastlane::Actions::AndroidGenerateApkFromAabAction do
  let(:aab_file_path) { 'Dev/My App/my-app.aab' }
  let(:apk_output_file_path) { 'Dev/My App/build/artifacts/my-universal-app.apk' }

  def expect_bundletool_call(aab, apk, *options)
    expect(Fastlane::Action).to receive('sh').with('command', '-v', 'bundletool', { print_command: false, print_command_output: false })
    allow(File).to receive(:file?).with(aab).and_return(true)
    expect(Fastlane::Action).to receive('sh').with(
      'bundletool', 'build-apks', '--mode', 'universal', '--bundle', aab,
      '--output-format', 'DIRECTORY', '--output', anything,
      *options
    )
    expect(FileUtils).to receive(:mkdir_p).with(File.dirname(apk))
    expect(FileUtils).to receive(:mv).with(anything, apk)
  end

  context 'when generating a signed APK' do
    let(:keystore_path) { 'Dev/My App/secrets/path/to/keystore' }
    let(:keystore_password) { 'keystore_password' }
    let(:keystore_key_alias) { 'keystore_key_alias' }
    let(:signing_key_password) { 'signing_key_password' }

    it 'calls the `bundletool` command with the correct arguments' do
      allow(File).to receive(:file?).with(keystore_path).and_return(true)
      expect_bundletool_call(
        aab_file_path, apk_output_file_path,
        '--ks', keystore_path, '--ks-pass', keystore_password, '--ks-key-alias', keystore_key_alias, '--key-pass', signing_key_password
      )

      output = run_described_fastlane_action(
        aab_file_path: aab_file_path,
        apk_output_file_path: apk_output_file_path,
        keystore_path: keystore_path,
        keystore_password: keystore_password,
        keystore_key_alias: keystore_key_alias,
        signing_key_password: signing_key_password
      )

      expect(output).to eq(apk_output_file_path)
    end
  end

  context 'when generating an unsigned APK' do
    it 'calls the `bundletool` command with the correct arguments' do
      expect_bundletool_call(aab_file_path, apk_output_file_path)

      output = run_described_fastlane_action(
        aab_file_path: aab_file_path,
        apk_output_file_path: apk_output_file_path
      )

      expect(output).to eq(apk_output_file_path)
    end
  end

  describe 'parameter inference' do
    it 'infers the AAB path from lane context if `SharedValues::GRADLE_AAB_OUTPUT_PATH` is set' do
      aab_path_from_context = 'path/from/context/my-app.aab'
      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::GRADLE_AAB_OUTPUT_PATH] = aab_path_from_context

      expect_bundletool_call(aab_path_from_context, apk_output_file_path)
      run_described_fastlane_action(
        apk_output_file_path: apk_output_file_path
      )

      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::GRADLE_AAB_OUTPUT_PATH] = nil
    end

    it 'infers the AAB path from lane context if `SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS` is set with only one value' do
      aab_paths_from_context = ['first/path/from/context/app.aab']
      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS] = aab_paths_from_context

      expect_bundletool_call(aab_paths_from_context.first, apk_output_file_path)
      run_described_fastlane_action(
        apk_output_file_path: apk_output_file_path
      )

      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS] = nil
    end

    it 'does not infer the AAB path from lane context if `SharedValues::GRADLE_AAB_OUTPUT_PATHS` has more than one value' do
      aab_paths_from_context = ['first/path/from/context/app.aab', 'second/path/from/context/app.aab']
      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS] = aab_paths_from_context

      expect do
        run_described_fastlane_action(
          apk_output_file_path: apk_output_file_path
        )
      end.to raise_error(described_class::NO_AAB_ERROR_MESSAGE)

      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::GRADLE_ALL_AAB_OUTPUT_PATHS] = nil
    end

    it 'infers the output path if none is provided' do
      inferred_apk_path = File.join(File.dirname(aab_file_path), "#{File.basename(aab_file_path, '.aab')}.apk")
      expect_bundletool_call(aab_file_path, inferred_apk_path)

      output = run_described_fastlane_action(
        aab_file_path: aab_file_path
      )

      expect(output).to eq(inferred_apk_path)
    end

    it 'infers the output file name if output path is a directory' do
      in_tmp_dir do |output_dir|
        inferred_apk_path = File.join(output_dir, "#{File.basename(aab_file_path, '.aab')}.apk")
        expect_bundletool_call(aab_file_path, inferred_apk_path)

        output = run_described_fastlane_action(
          aab_file_path: aab_file_path,
          apk_output_file_path: output_dir
        )

        expect(output).to eq(inferred_apk_path)
      end
    end
  end

  describe 'error handling' do
    it 'errors if bundletool is not installed' do
      allow(Fastlane::Action).to receive('sh').with('command', '-v', 'bundletool', any_args).and_raise
      expect(Fastlane::UI).to receive(:user_error!).with(described_class::MISSING_BUNDLETOOL_ERROR_MESSAGE).and_raise

      expect do
        run_described_fastlane_action(
          aab_file_path: aab_file_path,
          apk_output_file_path: apk_output_file_path
        )
      end.to raise_error(RuntimeError)
    end

    it 'errors if no input AAB file was provided nor can be inferred' do
      expect(Fastlane::Action).to receive('sh').with('command', '-v', 'bundletool', any_args)
      expect(Fastlane::UI).to receive(:user_error!).with(described_class::NO_AAB_ERROR_MESSAGE).and_raise

      expect do
        run_described_fastlane_action(
          apk_output_file_path: apk_output_file_path
        )
      end.to raise_error(RuntimeError)
    end

    it 'errors if the provided input AAB file does not exist' do
      expect(Fastlane::Action).to receive('sh').with('command', '-v', 'bundletool', any_args)
      allow(File).to receive(:file?).with(aab_file_path).and_return(false)
      expect(Fastlane::UI).to receive(:user_error!).with("The file `#{aab_file_path}` was not found. Please provide a path to an existing file.").and_raise

      expect do
        run_described_fastlane_action(
          aab_file_path: aab_file_path,
          apk_output_file_path: apk_output_file_path
        )
      end.to raise_error(RuntimeError)
    end
  end
end
