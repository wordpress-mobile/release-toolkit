require_relative './spec_helper'

describe Fastlane::Actions::AndroidSendAppSizeMetricsAction do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'app_size_metrics') }

  def test_app_size_action(fake_aab_size:, fake_apks:, expected_payload:, **other_action_args)
    in_tmp_dir do |tmp_dir|
      # Arrange
      output_file = File.join(tmp_dir, 'output-payload')
      aab_path = File.join(tmp_dir, 'fake.aab')
      File.write(aab_path, '-fake-aab-file-')
      allow(File).to receive(:size).with(aab_path).and_return(fake_aab_size)

      if other_action_args[:include_split_sizes] != false
        # Arrange: fake that apkanalyzer exists
        apkanalyzer_bin = File.join('__ANDROID_SDK_ROOT__FOR_TESTS__', 'cmdline-tools', 'latest', 'bin', 'apkanalyzer')
        allow(described_class).to receive(:find_apkanalyzer_binary).and_return(apkanalyzer_bin)
        allow(File).to receive(:executable?).with(apkanalyzer_bin).and_return(true)

        # Arrange: fake that bundletool exists and mock its call to create fake apks with corresponding apkanalyzer calls mocks
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

      # Act
      code = run_described_fastlane_action(
        api_url: File.join('file://localhost/', output_file),
        aab_path: aab_path,
        **other_action_args
      )

      # Asserts
      expect(code).to eq(201)
      expect(File).to exist(output_file)
      gzip_disabled = other_action_args[:use_gzip_content_encoding] == false
      generated_payload = gzip_disabled ? File.read(output_file) : Zlib::GzipReader.open(output_file, &:read)
      # Compare the payloads as pretty-formatted JSON, to make the diff in test failures more readable if one happen
      expect(JSON.pretty_generate(JSON.parse(generated_payload))).to eq(JSON.pretty_generate(expected_payload)), 'Decompressed JSON payload was not as expected'
      # Compare the payloads as raw uncompressed data as a final check
      expect(generated_payload).to eq(expected_payload.to_json)
    end
  end

  context 'when `include_split_sizes` is turned off' do
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
          expected_payload: expected,
          app_name: 'my-app',
          app_version_name: '10.2-rc-3',
          product_flavor: 'Vanilla',
          build_type: 'Release',
          source: 'unit-test',
          include_split_sizes: false
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
          ]
        }

        test_app_size_action(
          fake_aab_size: 123_456,
          fake_apks: {},
          expected_payload: expected,
          app_name: 'my-app',
          app_version_name: '10.2-rc-3',
          product_flavor: 'Vanilla',
          build_type: 'Release',
          source: 'unit-test',
          include_split_sizes: false,
          use_gzip_content_encoding: false
        )
      end
    end

    context 'when only providing an `universal_apk_path`' do
      it 'generates the expected payload containing the apk file size'
    end

    context 'when providing both an `aab_path` and an `universal_apk_path`' do
      it 'generates the expected payload containing the aab and universal apk file size'
    end
  end

  context 'when keeping the default value of `include_split_sizes` turned on' do
    context 'when only providing an `aab_path`' do
      it 'generates the expected payload containing the aab file size and optimized split sizes' do
        expected_fixture = File.join(test_data_dir, 'android-metrics-payload.json')
        expected = JSON.parse(File.read(expected_fixture))

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
          expected_payload: expected,
          app_name: 'wordpress',
          app_version_name: '19.8-rc-3',
          app_version_code: 1214,
          product_flavor: 'Vanilla',
          build_type: 'Release',
          source: 'unit-test'
        )
      end
    end

    context 'when only providing an `universal_apk_path`' do
      it 'generates the expected payload containing the apk file size and optimized file and download sizes'
    end

    context 'when providing both an `aab_path` and an `universal_apk_path`' do
      it 'generates the expected payload containing the aab and universal apk file size and optimized file and download sizes for all splits'
    end
  end
end
