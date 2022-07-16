require 'spec_helper'

describe Fastlane::Actions::AndroidFirebaseTestAction do
  let(:locale_sample_data) { File.read(File.join(__dir__, 'test-data', 'firebase', 'firebase-locale-list.json')) }
  let(:model_sample_data) { File.read(File.join(__dir__, 'test-data', 'firebase', 'firebase-model-list.json')) }
  let(:version_sample_data) { File.read(File.join(__dir__, 'test-data', 'firebase', 'firebase-version-list.json')) }

  before do |test|
    next if test.metadata[:calls_data_providers]

    allow(Fastlane::FirebaseDevice).to receive(:locale_data).and_return(locale_sample_data)
    allow(Fastlane::FirebaseDevice).to receive(:model_data).and_return(model_sample_data)
    allow(Fastlane::FirebaseDevice).to receive(:version_data).and_return(version_sample_data)

    # Some development environments may have this set
    ENV['GCP_PROJECT'] = nil
  end

  describe 'Calling the Action validates input' do
    it 'raises for missing `project_id`' do
      expect { run_action_without_key(:project_id) }.to raise_error "No value found for 'project_id'"
    end

    it 'raises for missing `apk_path` parameter' do
      expect { run_action_without_key(:apk_path) }.to raise_error 'The `:apk_path` parameter is required'
    end

    it 'raises for invalid `apk_path` parameter' do
      expect { run_action_with(:apk_path, 'foo') }.to raise_error 'Invalid application APK: foo'
    end

    it 'raises for missing `test_apk_path` parameter' do
      expect { run_action_without_key(:test_apk_path) }.to raise_error 'The `:test_apk_path` parameter is required'
    end

    it 'raises for invalid `test_apk_path` parameter' do
      expect { run_action_with(:test_apk_path, 'foo') }.to raise_error 'Invalid test APK: foo'
    end

    it 'raises for missing `model` parameter' do
      expect { run_action_without_key(:model) }.to raise_error 'The `:model` parameter is required'
    end

    it 'raises for invalid `model` parameter' do
      expect { run_action_with(:model, 'foo') }.to raise_error(/Invalid Model Name: foo/)
    end

    # This doesn't work because of a `fastlane` bug – everything becomes a string, even a missing parameter
    # it 'raises for missing `version` parameter' do
    #   expect{ run_action_without_key(:version) }.to raise_error "You must specify the `:version` parameter."
    # end

    it 'raises for string `version` parameter' do
      expect { run_action_with(:version, 'foo') }.to raise_error "'version' value must be a Integer! Found String instead."
    end

    it 'raises for out-of-range `version` parameter' do
      expect { run_action_with(:version, 99) }.to raise_error 'Invalid Version Number: 99. Valid Version Numbers: [18, 19, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]'
    end

    it 'raises for invalid `orientation` parameter' do
      expect { run_action_with(:orientation, 'foo') }.to raise_error 'Invalid Orientation: foo. Valid Orientations: ["portrait", "landscape"]'
    end

    it 'raises for invalid `type` parameter' do
      expect { run_action_with(:type, 'foo') }.to raise_error 'Invalid Test Type: foo. Valid Types: ["instrumentation", "robo"]'
    end

    def run_action_without_key(key)
      run_described_fastlane_action(defaults.except(key))
    end

    def run_action_with(key, value)
      values = defaults
      values[key] = value
      run_described_fastlane_action(values)
    end

    def defaults
      {
        project_id: '1234',
        apk_path: __FILE__,
        test_apk_path: __FILE__,
        model: 'Nexus5',
        version: 31
      }
    end
  end
end
