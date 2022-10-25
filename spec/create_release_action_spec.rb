require 'spec_helper'

describe Fastlane::Actions::CreateReleaseAction do
  describe 'run' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:test_version) { 'release/10.0' }
    let(:test_target) { 'dummy_target' }
    let(:test_prerelease) { false }
    let(:test_token) { 'GITHUB_TOKEN' }
    let(:github_helper) { class_double(Fastlane::Helper::GithubHelper) }

    before do
      allow(github_helper).to receive(:create_release)
      allow(Fastlane::Helper::GithubHelper).to receive(:new).and_return(github_helper)
    end

    it 'sets the github_token' do
      expect(Fastlane::Helper::GithubHelper).to receive(:new).with(github_token: test_token)
      described_class.run(mock_params)
    end

    it 'calls the create_release' do
      expect(github_helper).to receive(:create_release).with(
        repository: test_repo,
        version: test_version,
        target: test_target,
        description: '',
        assets: [],
        prerelease: test_prerelease
      )

      described_class.run(mock_params)
    end

    def mock_params
      {
        repository: test_repo,
        version: test_version,
        release_assets: [],
        target: test_target,
        prerelease: test_prerelease,
        github_token: test_token
      }
    end
  end

  describe 'available_options' do
    it 'has the correct length' do
      expect(described_class.available_options.length).to be(7)
    end

    it 'has the ConfigItem repository' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :repository))
    end

    it 'has the ConfigItem version' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :version))
    end

    it 'has the ConfigItem target' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :target))
    end

    it 'has the ConfigItem release_notes_file_path' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :release_notes_file_path))
    end

    it 'has the ConfigItem release_assets' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :release_assets))
    end

    it 'has the ConfigItem prerelease' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :prerelease))
    end

    it 'has the ConfigItem github_token' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :github_token))
    end
  end
end
