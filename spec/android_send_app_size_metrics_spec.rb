require_relative 'spec_helper'

describe Fastlane::Actions::AndroidSendAppSizeMetricsAction do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'app_size_metrics') }

  def test_app_size_action(fake_aab_size:, fake_apks:, fake_universal_apk_sizes:, expected_payload:, **other_action_args)
    in_tmp_dir do |tmp_dir|
      # Arrange
      output_file = File.join(tmp_dir, 'output-payload')
      aab_path = nil
      unless fake_aab_size.nil?
        aab_path = File.join(tmp_dir, 'fake.aab')
        File.write(aab_path, '-fake-aab-file-')
        allow(File).to receive(:size).with(aab_path).and_return(fake_aab_size)
      end
      universal_apk_path = nil
      unless fake_universal_apk_sizes.empty?
        universal_apk_path = File.join(tmp_dir, 'fake.apk')
        File.write(universal_apk_path, '-fake-universal-apk-file-')
        allow(File).to receive(:size).with(universal_apk_path).and_return(fake_universal_apk_sizes[0])
      end

      if other_action_args[:include_split_sizes] != false
        # Arrange: fake that apkanalyzer exists
        apkanalyzer_bin = File.join('__ANDROID_SDK_ROOT__FOR_TESTS__', 'cmdline-tools', 'latest', 'bin', 'apkanalyzer')
        allow(described_class).to receive(:find_apkanalyzer_binary).and_return(apkanalyzer_bin)
        allow(File).to receive(:executable?).with(apkanalyzer_bin).and_return(true)

        unless fake_apks.empty?
          # Arrange: fake that `bundletool` exists and mock its call to create fake apks with corresponding apkanalyzer calls mocks
          allow(Fastlane::Action).to receive(:sh).with('command', '-v', 'bundletool', anything)
          allow(Fastlane::Action).to receive(:sh).with('bundletool', 'build-apks', '--bundle', aab_path, '--output-format', 'DIRECTORY', '--output', anything) do |*args|
            bundletool_tmpdir = args.last
            FileUtils.mkdir(File.join(bundletool_tmpdir, 'splits'))
            fake_apks.each do |apk_name, sizes|
              apk_path = File.join(bundletool_tmpdir, 'splits', apk_name.to_s)
              File.write(apk_path, "Fake APK file (#{sizes})")
              allow(Fastlane::Action).to receive(:sh).with(apkanalyzer_bin, 'apk', 'file-size', apk_path, anything).and_return(sizes[0].to_s)
              allow(Fastlane::Action).to receive(:sh).with(apkanalyzer_bin, 'apk', 'download-size', apk_path, anything).and_return(sizes[1].to_s)
            end
          end
        end
        unless fake_universal_apk_sizes.empty?
          allow(Fastlane::Action).to receive(:sh).with(apkanalyzer_bin, 'apk', 'file-size', universal_apk_path, anything).and_return(fake_universal_apk_sizes[1].to_s)
          allow(Fastlane::Action).to receive(:sh).with(apkanalyzer_bin, 'apk', 'download-size', universal_apk_path, anything).and_return(fake_universal_apk_sizes[2].to_s)
        end
      end

      # Act
      action_params = {
        api_url: File.join('file://localhost/', output_file),
        aab_path: aab_path,
        universal_apk_path: universal_apk_path,
        **other_action_args
      }.compact
      code = run_described_fastlane_action(action_params)

      # Asserts
      expect(code).to eq(201)
      expect(File).to exist(output_file)
      gzip_disabled = other_action_args[:use_gzip_content_encoding] == false
      generated_payload = gzip_disabled ? File.read(output_file) : Zlib::GzipReader.open(output_file, &:read)

      generated_payload = JSON.parse(generated_payload, symbolize_names: true)
      expect(generated_payload.fetch(:meta, []).to_set).to eq(expected_payload[:meta].to_set)
      expect(generated_payload.fetch(:metrics, []).to_set).to eq(expected_payload[:metrics].to_set)
    end
  end

  context 'when `include_split_sizes` is turned off' do
    let(:common_action_args) do
      {
        app_name: 'my-app',
        app_version_name: '10.2-rc-3',
        product_flavor: 'Vanilla',
        build_type: 'Release',
        source: 'unit-test',
        include_split_sizes: false
      }
    end

    context 'when only providing an `aab_path`' do
      it 'generates the expected payload compressed by default' do
        expected = {
          meta: [
            { name: 'Platform', value: 'Android' },
            { name: 'App Name', value: 'my-app' },
            { name: 'App Version', value: '10.2-rc-3' },
            { name: 'Product Flavor', value: 'Vanilla' },
            { name: 'Build Type', value: 'Release' },
            { name: 'Source', value: 'unit-test' },
          ],
          metrics: [
            { name: 'AAB File Size', value: 123_456 },
          ]
        }

        test_app_size_action(
          fake_aab_size: 123_456,
          fake_apks: {},
          fake_universal_apk_sizes: [],
          expected_payload: expected,
          **common_action_args
        )
      end

      it 'generates the expected payload uncompressed when disabling gzip' do
        expected = {
          meta: [
            { name: 'Platform', value: 'Android' },
            { name: 'App Name', value: 'my-app' },
            { name: 'App Version', value: '10.2-rc-3' },
            { name: 'Product Flavor', value: 'Vanilla' },
            { name: 'Build Type', value: 'Release' },
            { name: 'Source', value: 'unit-test' },
          ],
          metrics: [
            { name: 'AAB File Size', value: 123_456 },
            { name: 'Universal APK File Size', value: 56_789 },
          ]
        }

        test_app_size_action(
          fake_aab_size: 123_456,
          fake_apks: {},
          fake_universal_apk_sizes: [56_789],
          expected_payload: expected,
          **common_action_args,
          use_gzip_content_encoding: false
        )
      end
    end

    context 'when only providing an `universal_apk_path`' do
      it 'generates the expected payload containing the apk file size' do
        expected = {
          meta: [
            { name: 'Platform', value: 'Android' },
            { name: 'App Name', value: 'my-app' },
            { name: 'App Version', value: '10.2-rc-3' },
            { name: 'Product Flavor', value: 'Vanilla' },
            { name: 'Build Type', value: 'Release' },
            { name: 'Source', value: 'unit-test' },
          ],
          metrics: [
            { name: 'Universal APK File Size', value: 567_654_321 },
          ]
        }

        test_app_size_action(
          fake_aab_size: nil,
          fake_apks: {},
          fake_universal_apk_sizes: [567_654_321],
          expected_payload: expected,
          **common_action_args
        )
      end
    end

    context 'when providing both an `aab_path` and an `universal_apk_path`' do
      it 'generates the expected payload containing the aab and universal apk file size' do
        expected = {
          meta: [
            { name: 'Platform', value: 'Android' },
            { name: 'App Name', value: 'my-app' },
            { name: 'App Version', value: '10.2-rc-3' },
            { name: 'Product Flavor', value: 'Vanilla' },
            { name: 'Build Type', value: 'Release' },
            { name: 'Source', value: 'unit-test' },
          ],
          metrics: [
            { name: 'AAB File Size', value: 123_456 },
            { name: 'Universal APK File Size', value: 567_654_321 },
          ]
        }

        test_app_size_action(
          fake_aab_size: 123_456,
          fake_apks: {},
          fake_universal_apk_sizes: [567_654_321],
          expected_payload: expected,
          **common_action_args
        )
      end
    end
  end

  context 'when keeping the default value of `include_split_sizes` turned on' do
    let(:common_action_args) do
      {
        app_name: 'wordpress',
        app_version_name: '19.8-rc-3',
        app_version_code: 1214,
        product_flavor: 'Vanilla',
        build_type: 'Release',
        source: 'unit-test'
      }
    end

    context 'when only providing an `aab_path`' do
      it 'generates the expected payload containing the aab file size and optimized split sizes' do
        expected_fixture = File.join(test_data_dir, 'android-metrics-payload-aab.json')
        expected = JSON.parse(File.read(expected_fixture), symbolize_names: true)

        test_app_size_action(
          fake_aab_size: 987_654_321,
          fake_apks: {
            'base-arm64_v8a.apk': [164_080, 64_080],
            'base-arm64_v8a_2.apk': [164_082, 64_082],
            'base-armeabi.apk': [150_000, 50_000],
            'base-armeabi_2.apk': [150_002, 50_002],
            'base-armeabi_v7a.apk': [150_070, 50_070],
            'base-armeabi_v7a_2.apk': [150_072, 50_072]
          },
          fake_universal_apk_sizes: [],
          expected_payload: expected,
          **common_action_args
        )
      end
    end

    context 'when only providing an `universal_apk_path`' do
      it 'generates the expected payload containing the apk file size and optimized file and download sizes' do
        expected_fixture = File.join(test_data_dir, 'android-metrics-payload-apk.json')
        expected = JSON.parse(File.read(expected_fixture), symbolize_names: true)

        test_app_size_action(
          fake_aab_size: nil,
          fake_apks: {},
          fake_universal_apk_sizes: [567_654_321, 555_000, 533_000],
          expected_payload: expected,
          **common_action_args
        )
      end
    end

    context 'when providing both an `aab_path` and an `universal_apk_path`' do
      it 'generates the expected payload containing the aab and universal apk file size and optimized file and download sizes for all splits' do
        expected_fixture = File.join(test_data_dir, 'android-metrics-payload-aab+apk.json')
        expected = JSON.parse(File.read(expected_fixture), symbolize_names: true)

        test_app_size_action(
          fake_aab_size: 987_654_321,
          fake_apks: {
            'base-arm64_v8a.apk': [164_080, 64_080],
            'base-arm64_v8a_2.apk': [164_082, 64_082],
            'base-armeabi.apk': [150_000, 50_000],
            'base-armeabi_2.apk': [150_002, 50_002],
            'base-armeabi_v7a.apk': [150_070, 50_070],
            'base-armeabi_v7a_2.apk': [150_072, 50_072]
          },
          fake_universal_apk_sizes: [567_654_321, 555_000, 533_000],
          expected_payload: expected,
          **common_action_args
        )
      end
    end
  end
end
