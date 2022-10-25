require 'spec_helper'

describe Fastlane::Actions::GetPrsListAction do
  describe 'run' do
    let(:test_repo) { 'repo-test/project-test' }
    let(:test_milestone) { 'release/10.0' }
    let(:file_like_object) { double('file like object') }
    let(:test_token) { 'GITHUB_TOKEN' }
    let(:github_helper) { class_double(Fastlane::Helper::GithubHelper) }

    before do
      allow(File).to receive(:open).and_return(file_like_object)
      allow(github_helper).to receive(:get_prs_for_milestone).and_return([])
      allow(Fastlane::Helper::GithubHelper).to receive(:new).and_return(github_helper)
    end

    it 'sets the github_token' do
      expect(Fastlane::Helper::GithubHelper).to receive(:new).with(github_token: test_token)
      described_class.run(mock_params)
    end

    it 'calls the get_prs_for_milestone' do
      expect(github_helper).to receive(:get_prs_for_milestone).with(test_repo, test_milestone)
      described_class.run(mock_params)
    end

    def mock_params
      {
        repository: test_repo,
        milestone: test_milestone,
        report_path: '',
        github_token: test_token
      }
    end
  end

  describe 'available_options' do
    it 'has the correct length' do
      expect(described_class.available_options.length).to be(4)
    end

    it 'has the ConfigItem repository' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :repository))
    end

    it 'has the ConfigItem report_path' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :report_path))
    end

    it 'has the ConfigItem milestone' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :milestone))
    end

    it 'has the ConfigItem github_token' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :github_token))
    end
  end
end
