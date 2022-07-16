require 'spec_helper'

describe Fastlane::Actions::FirebaseLoginAction do
  describe 'Calling the Action Validates Input' do
    it 'raises for missing `key_file` parameter' do
      expect { run_described_fastlane_action({}) }.to raise_error 'The `:key_file` parameter is required'
    end

    it 'raises for invalid `key_file` parameter' do
      expect { run_described_fastlane_action({key_file: 'foo'}) }.to raise_error 'No Google Cloud Key file found at: foo'
    end
  end
end
