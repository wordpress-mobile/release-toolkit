require 'spec_helper'

describe Fastlane::FirebaseTestRunner do
  let(:default_file) { '/etc/hosts' }
  let(:runner_temp_file) { Tempfile.new(%w[output log]).path }

  describe '#initialize' do
    it 'raises for missing key file' do
      expect { described_class.new(key_file: 'foo') }.to raise_exception('Unable to find key file: foo')
    end
  end

  describe '#verify_has_gcloud_binary' do
    it 'runs the correct command' do
      expect(Fastlane::Action).to receive('sh').with('command', '-v', 'gcloud', { print_command: false, print_command_output: false })
      described_class.verify_has_gcloud_binary!
    end

    it 'raises for missing binary' do
      allow(Fastlane::Action).to receive('sh').with('command', '-v', 'gcloud', { print_command: false, print_command_output: false }).and_raise
      expect(Fastlane::UI).to receive(:user_error!)
      described_class.verify_has_gcloud_binary!
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
      allow(Fastlane::Action).to receive('sh').with("gcloud firebase test android run --type instrumentation --app #{default_file} --test #{default_file} --device device --verbosity info 2>&1 | tee #{runner_temp_file}")
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

    def run_tests(apk_path: default_file, test_apk_path: default_file, device: 'device', type: 'instrumentation')
      Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH] = runner_temp_file
      subject.run_tests(apk_path: apk_path, test_apk_path: test_apk_path, device: device, type: type)
    end
  end

  describe '.download_result_files' do
    subject(:runner) do
      runner = described_class.new(key_file: __FILE__, verify_gcloud_binary: false)
      runner.instance_variable_set(:@has_authenticated, true)

      runner
    end

    let(:empty_test_log) { Fastlane::FirebaseTestLabResult.new(log_file_path: EMPTY_FIREBASE_TEST_LOG_PATH) }
    let(:passed_test_log) { Fastlane::FirebaseTestLabResult.new(log_file_path: PASSED_FIREBASE_TEST_LOG_PATH) }

    it 'raises for invalid result' do
      expect { run_download(result: 'foo') }.to raise_exception('You must pass a `FirebaseTestLabResult` to this method')
    end

    it 'raises for invalid destination' do
      expect { run_download(result: empty_test_log) }.to raise_exception('Log File doesn\'t contain a raw results URL')
    end

    def run_download(result: passed_test_log, destination: '/tmp/test', project_id: 0, key_file_path: 'invalid')
      subject.download_result_files(
        result: result,
        destination: destination,
        project_id: project_id,
        key_file_path: key_file_path
      )
    end
  end
end
