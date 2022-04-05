require 'spec_helper'

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

  describe 'has_gcloud_binary' do
    it 'runs the correct command' do
      expect(subject).to receive(:system).with('command -v gcloud > /dev/null').and_return true
      described_class.has_gcloud_binary
    end

    it 'raises for missing binary' do
      expect(subject).to receive(:system).with('command -v gcloud > /dev/null').and_return false
      expect(Fastlane::UI).to receive(:user_error!)
      described_class.has_gcloud_binary
    end
  end

  describe 'run_tests' do
    it 'runs the correct command' do
      expect(Fastlane::Action).to receive('sh').with(
        'gcloud', 'firebase', 'test', 'android', 'run',
        '--type', 'instrumentation',
        '--app', __FILE__,
        '--test', __FILE__,
        '--device', 'device'
      )

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
  end

  def run_tests(apk_path: __FILE__, test_apk_path: __FILE__, device: 'device', type: 'instrumentation')
    described_class.run_tests(apk_path: apk_path, test_apk_path: test_apk_path, device: device, type: type)
  end
end
