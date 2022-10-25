require 'spec_helper'

describe Fastlane::Actions::CreateNewMilestoneAction do
  describe 'run' do
    let(:test_repository) { 'test/test' }
    let(:test_milestone_duration) { 10 }
    let(:test_freeze_days) { 5 }
    let(:test_submit_appstore) { false }
    let(:test_milestone_number) { 1234 }
    let(:test_milestone_duedate) { '2022-11-01T23:39:01Z'.to_time.utc }
    let(:test_milestone) { { title: 'milestone', due_on: '2022-10-22T23:39:01Z' } }
    let(:test_token) { 'GITHUB_TOKEN' }
    let(:github_helper) { class_double(Fastlane::Helper::GithubHelper) }

    before do
      allow(github_helper).to receive(:create_milestone)
      allow(github_helper).to receive(:get_last_milestone).and_return(test_milestone)
      allow(Fastlane::Helper::GithubHelper).to receive(:new).and_return(github_helper)
      allow(Fastlane::Helper::Ios::VersionHelper).to receive(:calc_next_release_version).and_return(test_milestone_number)
    end

    it 'sets the github_token' do
      expect(Fastlane::Helper::GithubHelper).to receive(:new).with(github_token: test_token)
      described_class.run(mock_params)
    end

    it 'calls the get_last_milestone' do
      expect(github_helper).to receive(:get_last_milestone).with(test_repository)
      described_class.run(mock_params)
    end

    it 'calls the create_milestone' do
      expect(github_helper).to receive(:create_milestone).with(
        test_repository,
        test_milestone_number,
        test_milestone_duedate,
        test_milestone_duration,
        test_freeze_days,
        test_submit_appstore
      )

      described_class.run(mock_params)
    end

    def mock_params(freeze: false)
      {
        repository: test_repository,
        milestone_duration: test_milestone_duration,
        number_of_days_from_code_freeze_to_release: test_freeze_days,
        need_appstore_submission: test_submit_appstore,
        github_token: test_token
      }
    end
  end

  describe 'available_options' do
    it 'has the correct length' do
      expect(described_class.available_options.length).to be(5)
    end

    it 'has the ConfigItem repository' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :repository))
    end

    it 'has the ConfigItem need_appstore_submission' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :need_appstore_submission))
    end

    it 'has the ConfigItem milestone_duration' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :milestone_duration))
    end

    it 'has the ConfigItem number_of_days_from_code_freeze_to_release' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :number_of_days_from_code_freeze_to_release))
    end

    it 'has the ConfigItem github_token' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :github_token))
    end
  end
end
