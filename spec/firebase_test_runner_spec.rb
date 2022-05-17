require 'spec_helper'

DEFAULT_FILE = '/etc/hosts'.freeze
RUNNER_TEMP_FILE = Tempfile.new(%w[output log]).path

describe Fastlane::FirebaseTestRunner do
  describe '#initialize' do
    it 'raises for missing key file' do
      expect { described_class.new(key_file: 'foo') }.to raise_exception('Unable to find key file: foo')
    end
  end

  describe '#verify_has_gcloud_binary' do
    it 'runs the correct command' do
      expect(Fastlane::Action).to receive('sh').with('command -v gcloud > /dev/null')
      described_class.verify_has_gcloud_binary
    end

    it 'raises for missing binary' do
      allow(Fastlane::Action).to receive('sh').with('command -v gcloud > /dev/null').and_raise
      expect(Fastlane::UI).to receive(:user_error!)
      described_class.verify_has_gcloud_binary
    end
  end

  describe '.authenticate_if_needed' do
    subject(:runner) { described_class.new(key_file: __FILE__, verify_gcloud_binary: false) }

    it 'only runs if needed' do
      runner.instance_variable_set(:@has_authenticated, true)
      expect(Fastlane::Action).not_to receive('sh')

      runner.authenticate_if_needed
    end

    it 'runs the right command' do
      allow(Fastlane::Action).to receive('sh').with('gcloud', 'auth', 'activate-service-account', '--key-file', __FILE__)
      runner.authenticate_if_needed
    end
  end

  describe '.run_tests' do
    subject(:runner) do
      runner = described_class.new(key_file: __FILE__, verify_gcloud_binary: false)
      runner.instance_variable_set(:@has_authenticated, true)

      runner
    end

    it 'runs the correct command' do
      allow(Fastlane::Action).to receive('sh').with("gcloud firebase test android run --type instrumentation --app #{DEFAULT_FILE} --test #{DEFAULT_FILE} --device device --verbosity info 2>&1 | tee #{RUNNER_TEMP_FILE}")
      run_tests
    end

    it 'raises for invalid app path' do
      expect { run_tests(apk_path: 'foo') }.to raise_exception('Unable to find apk: foo')
    end

    it 'raises for invalid test path' do
      expect { run_tests(test_apk_path: 'bar') }.to raise_exception('Unable to find apk: bar')
    end

    it 'raises for invalid type' do
      expect { run_tests(type: 'foo') }.to raise_exception('Invalid Type: foo')
    end

    def run_tests(apk_path: DEFAULT_FILE, test_apk_path: DEFAULT_FILE, device: 'device', type: 'instrumentation')
      Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH] = RUNNER_TEMP_FILE
      subject.run_tests(apk_path: apk_path, test_apk_path: test_apk_path, device: device, type: type)
    end
  end
end
