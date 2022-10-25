require 'spec_helper'

describe Fastlane::Actions::AndroidDownloadFileByVersionAction do
  describe 'run' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:test_tag) { 'release/10.0' }
    let(:test_version) { '10.0' }
    let(:test_file) { 'test-file.xml' }
    let(:test_folder) { 'test-folder' }
    let(:test_token) { 'GITHUB_TOKEN' }
    let(:github_helper) { class_double(Fastlane::Helper::GithubHelper) }

    before do
      allow(github_helper).to receive(:download_file_from_tag) # .and_return(nil)
      allow(Fastlane::Helper::GithubHelper).to receive(:new).and_return(github_helper)
      allow(Fastlane::Helper::Android::VersionHelper).to receive(:get_library_version_from_gradle_config).and_return(test_version)
    end

    it 'includes the github_token' do
      expect(Fastlane::Helper::GithubHelper).to receive(:new).with(github_token: test_token)
      described_class.run(mock_params)
    end

    it 'calls the download_file_from_tag' do
      expect(github_helper).to receive(:download_file_from_tag).with(
        repository: test_repo,
        tag: test_tag,
        file_path: test_file,
        download_folder: test_folder
      )

      described_class.run(mock_params)
    end

    def mock_params
      {
        repository: test_repo,
        github_release_prefix: 'release/',
        file_path: test_file,
        download_folder: test_folder,
        github_token: test_token
      }
    end
  end

  describe 'available_options' do
    it 'has the correct length' do
      expect(described_class.available_options.length).to be(7)
    end

    it 'has the ConfigItem library_name' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :library_name))
    end

    it 'has the ConfigItem import_key' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :import_key))
    end

    it 'has the ConfigItem repository' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :repository))
    end

    it 'has the ConfigItem file_path' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :file_path))
    end

    it 'has the ConfigItem download_folder' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :download_folder))
    end

    it 'has the ConfigItem github_release_prefix' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :github_release_prefix))
    end

    it 'has the ConfigItem github_token' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :github_token))
    end
  end
end
