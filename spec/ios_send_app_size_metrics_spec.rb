require_relative './spec_helper'

describe Fastlane::Actions::IosSendAppSizeMetricsAction do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'app_size_metrics') }
  let(:fake_ipa_size) { 1337 } # The value used in the `app-thinning.plist` and `ios-metrics-payload.json` fixtures

  def test_app_size_action(fake_ipa_size:, expected_payload:, **other_action_args)
    in_tmp_dir do |tmp_dir|
      # Arrange
      output_file = File.join(tmp_dir, 'output-payload')
      ipa_path = File.join(tmp_dir, 'fake.ipa')
      File.write(ipa_path, '-fake-ipa-file-')
      allow(File).to receive(:size).with(ipa_path).and_return(fake_ipa_size)

      # Act
      code = run_described_fastlane_action(
        api_url: File.join('file://localhost/', output_file),
        ipa_path: ipa_path,
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

  context 'when only providing an `.ipa` file with no `app-thinning.plist` file' do
    it 'generates the expected payload, compressed by default' do
      expected = {
        meta: [
          { name: 'Platform', value: 'iOS' },
          { name: 'App Name', value: 'my-app' },
          { name: 'App Version', value: '1.2.3' },
          { name: 'Build Type', value: 'beta' },
          { name: 'Source', value: 'unit-test' },
        ],
        metrics: [
          { name: 'File Size', value: 123_456 },
        ]
      }

      test_app_size_action(
        fake_ipa_size: 123_456,
        expected_payload: expected,
        app_name: 'my-app',
        build_type: 'beta',
        app_version: '1.2.3',
        source: 'unit-test'
      )
    end

    it 'generates the expected payload, uncompressed when disabling gzip' do
      expected = {
        meta: [
          { name: 'Platform', value: 'iOS' },
          { name: 'App Name', value: 'my-app' },
          { name: 'App Version', value: '1.2.3' },
          { name: 'Build Type', value: 'beta' },
          { name: 'Source', value: 'unit-test' },
        ],
        metrics: [
          { name: 'File Size', value: 123_456 },
        ]
      }

      test_app_size_action(
        fake_ipa_size: 123_456,
        expected_payload: expected,
        app_name: 'my-app',
        build_type: 'beta',
        app_version: '1.2.3',
        source: 'unit-test',
        use_gzip_content_encoding: false
      )
    end
  end

  context 'when using both an `.ipa` file and an existing `app-thinning.plist` file' do
    it 'generates the expected payload containing both the Universal and optimized thinned sizes' do
      app_thinning_plist_path = File.join(test_data_dir, 'app-thinning.plist')
      expected_fixture = File.join(test_data_dir, 'ios-metrics-payload.json')
      expected = JSON.parse(File.read(expected_fixture))

      test_app_size_action(
        fake_ipa_size: fake_ipa_size,
        expected_payload: expected,
        app_thinning_plist_path: app_thinning_plist_path,
        app_name: 'wordpress',
        build_type: 'internal',
        app_version: '19.8.0.2',
        source: 'unit-test'
      )
    end
  end
end
