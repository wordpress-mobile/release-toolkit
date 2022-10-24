require 'spec_helper'

describe Fastlane::Actions::CloseMilestoneAction do
  describe 'run' do
    let(:test_repository) { 'test/test' }
    let(:test_milestone_title) { 'milestone_title' }
    let(:test_milestone) { { number: 1234 } }
    let(:test_token) { 'GITHUB_TOKEN' }
    let(:github_helper) { class_double(Fastlane::Helper::GithubHelper) }

    before do
      allow(github_helper).to receive(:update_milestone)
      allow(github_helper).to receive(:get_milestone).and_return(test_milestone)
      allow(Fastlane::Helper::GithubHelper).to receive(:new).and_return(github_helper)
    end

    it 'sets the github_token' do
      expect(Fastlane::Helper::GithubHelper).to receive(:new).with(github_token: test_token)
      described_class.run(mock_params)
    end

    it 'calls the get_milestone' do
      expect(github_helper).to receive(:get_milestone).with(test_repository, test_milestone_title)
      described_class.run(mock_params)
    end

    it 'calls the update_milestone' do
      expect(github_helper).to receive(:update_milestone).with(
        repository: test_repository,
        number: 1234,
        options: { state: 'closed' }
      )

      described_class.run(mock_params)
    end

    def mock_params
      {
        repository: test_repository,
        milestone: test_milestone_title,
        github_token: test_token
      }
    end
  end

  describe 'available_options' do
    it 'has the correct length' do
      expect(described_class.available_options.length).to be(3)
    end

    it 'has the ConfigItem repository' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :repository))
    end

    it 'has the ConfigItem milestone' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :milestone))
    end

    it 'has the ConfigItem github_token' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :github_token))
    end
  end
end
