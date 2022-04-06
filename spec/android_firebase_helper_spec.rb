require 'spec_helper'

DEFAULT_FILE = '/etc/hosts'.freeze

describe Fastlane::Helper::Android::FirebaseHelper do
  describe 'setup' do
    it 'runs the correct command' do
      expect(Fastlane::Action).to receive('sh').with('gcloud', 'auth', 'activate-service-account', '--key-file', __FILE__)
      described_class.setup(key_file: __FILE__)
    end

    it 'raises for missing key file' do
      expect { described_class.setup(key_file: 'foo') }.to raise_exception('Unable to find key file: foo')
    end
  end

  describe 'set_project' do
    it 'runs the correct command' do
      expect(Fastlane::Action).to receive('sh').with('gcloud', 'config', 'set', 'project', 'foo-bar')
      described_class.project = 'foo-bar'
    end
  end

  describe 'verify_has_gcloud_binary' do
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

  describe 'run_tests' do
    it 'runs the correct command' do
      allow(Fastlane::Action).to receive('sh').with("gcloud firebase test android run --type instrumentation --app #{DEFAULT_FILE} --test #{DEFAULT_FILE} --device device --verbosity info 2>&1 | tee output.log")
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
      Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH] = 'output.log'
      described_class.run_tests(apk_path: apk_path, test_apk_path: test_apk_path, device: device, type: type)
    end
  end

  describe 'more_details_url' do
    it 'returns the "more details url"' do
      Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH] = failed_firebase_test_log_path
      expect(described_class.more_details_url).to eq 'https://console.firebase.google.com/project/redacted/testlab/histories/bh.edfd947f2636efe3/matrices/4770383643393920434'
    end

    it 'returns nil if not present' do
      Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH] = File.join(__dir__, 'test-data', 'empty.json')
      expect(described_class.more_details_url).to be_nil
    end

    it 'returns nil for an invalid file' do
      Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH] = 'foo'
      expect(described_class.more_details_url).to be_nil
    end
  end

  describe 'raw_results_paths' do
    it 'returns the bucket name for the raw results' do
      Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH] = failed_firebase_test_log_path
      expect(described_class.raw_results_paths[:bucket]).to eq 'test-lab-wjdmcn8vd90jx-wfb9uburfx80m'
    end

    it 'returns the prefix for the raw results' do
      Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH] = failed_firebase_test_log_path
      expect(described_class.raw_results_paths[:prefix]).to eq '2022-04-05_18:37:28.338803_oTen'
    end

    it 'returns nil if not present' do
      Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH] = File.join(__dir__, 'test-data', 'empty.json')
      expect(described_class.raw_results_paths).to be_nil
    end

    it 'returns nil for an invalid file' do
      Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH] = 'foo'
      expect(described_class.raw_results_paths).to be_nil
    end
  end

  def failed_firebase_test_log_path
    File.join(__dir__, 'test-data', 'firebase', 'failed-firebase-test-lab-run.log')
  end
end
