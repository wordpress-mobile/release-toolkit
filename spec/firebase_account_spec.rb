require 'spec_helper'

describe Fastlane::FirebaseAccount do
  let(:logged_out_status) { File.read(File.join(__dir__, 'test-data', 'firebase', 'firebase-empty-user-list.json')) }
  let(:logged_in_status) { File.read(File.join(__dir__, 'test-data', 'firebase', 'firebase-authenticated-user-list.json')) }

  describe 'authenticated?' do
    it 'correctly parses logged out status' do
      allow(described_class).to receive(:auth_status_data).and_return(logged_out_status)
      expect(described_class.authenticated?).to be false
    end

    it 'correctly parses logged in status' do
      allow(described_class).to receive(:auth_status_data).and_return(logged_in_status)
      expect(described_class.authenticated?).to be true
    end
  end

  describe '#activate_service_account_with_key_file' do
    it 'runs the right command' do
      expect(Fastlane::Actions).to receive('sh').with('gcloud', 'auth', 'activate-service-account', '--key-file', 'foo')
      described_class.activate_service_account_with_key_file('foo')
    end
  end

  describe '#auth_status_data' do
    it 'runs the right command' do
      expect(Fastlane::Actions).to receive('sh').with('gcloud', 'auth', 'list', '--format', 'json', log: false)
      described_class.auth_status_data
    end
  end
end
