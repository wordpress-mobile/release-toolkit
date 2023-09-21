require 'spec_helper'

describe Fastlane::FirebaseTestRunner do
  let(:default_file) { Tempfile.new('file').path }
  let(:runner_temp_file) { Tempfile.new(%w[output log]).path }

  describe '#verify_has_gcloud_binary!' do
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

  describe '#verify_logged_in!' do
    it 'raises if not logged in' do
      allow(Fastlane::FirebaseAccount).to receive(:authenticated?).and_return(false)
      expect(Fastlane::UI).to receive(:user_error!)
      described_class.verify_logged_in!
    end
  end

  describe '#run_tests' do
    it 'runs the correct command' do
      allow(Fastlane::Action).to receive('sh').with("gcloud firebase test android run --project foo-bar-baz --type instrumentation --app #{default_file} --test #{default_file} --device device --verbosity info 2>&1 | tee #{runner_temp_file}")
      run_tests
    end

    it 'includes and properly escapes the test targets if any are provided' do
      allow(Fastlane::Action).to receive('sh').with(
        "gcloud firebase test android run --project foo-bar-baz --type instrumentation --app #{default_file} --test #{default_file} --test-targets notPackage\\ org.wordpress.android.ui.screenshots --device device --verbosity info 2>&1 | tee #{runner_temp_file}"
      )
      run_tests(test_targets: 'notPackage org.wordpress.android.ui.screenshots')
    end

    it 'properly escapes the app path' do
      temp_file_path = File.join(Dir.tmpdir, 'path with spaces.txt')
      expected_temp_file_path = File.join(Dir.tmpdir, 'path\ with\ spaces.txt')
      File.write(temp_file_path, '')

      allow(Fastlane::Action).to receive('sh').with("gcloud firebase test android run --project foo-bar-baz --type instrumentation --app #{expected_temp_file_path} --test #{default_file} --device device --verbosity info 2>&1 | tee #{runner_temp_file}")
      run_tests(apk_path: temp_file_path)
    end

    it 'properly escapes the test path' do
      temp_file_path = File.join(Dir.tmpdir, 'path with spaces.txt')
      expected_temp_file_path = File.join(Dir.tmpdir, 'path\ with\ spaces.txt')
      File.write(temp_file_path, '')

      allow(Fastlane::Action).to receive('sh').with("gcloud firebase test android run --project foo-bar-baz --type instrumentation --app #{default_file} --test #{expected_temp_file_path} --device device --verbosity info 2>&1 | tee #{runner_temp_file}")
      run_tests(test_apk_path: temp_file_path)
    end

    it 'properly escapes the device name' do
      allow(Fastlane::Action).to receive('sh').with("gcloud firebase test android run --project foo-bar-baz --type instrumentation --app #{default_file} --test #{default_file} --device Nexus\\ 5 --verbosity info 2>&1 | tee #{runner_temp_file}")
      run_tests(device: 'Nexus 5')
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

    def run_tests(project_id: 'foo-bar-baz', apk_path: default_file, test_apk_path: default_file, device: 'device', test_targets: nil, type: 'instrumentation')
      Fastlane::Actions.lane_context[:FIREBASE_TEST_LOG_FILE_PATH] = runner_temp_file
      described_class.run_tests(
        project_id:,
        apk_path:,
        test_apk_path:,
        device:,
        test_targets:,
        type:
      )
    end
  end

  describe '#download_result_files' do
    let(:empty_test_log) { Fastlane::FirebaseTestLabResult.new(log_file_path: EMPTY_FIREBASE_TEST_LOG_PATH) }
    let(:passed_test_log) { Fastlane::FirebaseTestLabResult.new(log_file_path: PASSED_FIREBASE_TEST_LOG_PATH) }

    it 'raises for invalid result' do
      expect { run_download(result: 'foo') }.to raise_exception('You must pass a `FirebaseTestLabResult` to this method')
    end

    it 'raises for invalid destination' do
      expect { run_download(result: empty_test_log) }.to raise_exception('Log File doesn\'t contain a raw results URL')
    end

    def run_download(result: passed_test_log, destination: '/tmp/test', project_id: 'foo-bar-baz', key_file_path: 'invalid')
      described_class.download_result_files(
        result:,
        destination:,
        project_id:,
        key_file_path:
      )
    end
  end
end
