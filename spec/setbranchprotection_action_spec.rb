require 'spec_helper'

describe Fastlane::Actions::SetbranchprotectionAction do
  describe 'run' do
    let(:test_repository) { 'test/test' }
    let(:test_branch) { 'test_branch' }
    let(:test_token) { 'GITHUB_TOKEN' }
    let(:github_helper) { class_double(Fastlane::Helper::GithubHelper) }

    before do
      allow(github_helper).to receive(:set_branch_protection)
      allow(Fastlane::Helper::GithubHelper).to receive(:new).and_return(github_helper)
    end

    it 'sets the github_token' do
      expect(Fastlane::Helper::GithubHelper).to receive(:new).with(github_token: test_token)
      described_class.run(mock_params)
    end

    it 'calls the set_branch_protection' do
      expect(github_helper).to receive(:set_branch_protection).with(
        repository: test_repository,
        branch: test_branch,
        options: branch_options
      )

      described_class.run(mock_params)
    end

    def mock_params
      {
        repository: test_repository,
        branch: test_branch,
        github_token: test_token
      }
    end

    def branch_options
      {
        enforce_admins: nil,
        required_pull_request_reviews: {
          dismiss_stale_reviews: false,
          require_code_owner_reviews: false,
          url: 'https://api.github.com/repos/test/test/branches/test_branch/protection/required_pull_request_reviews'
        },
        restrictions: {
          teams: [],
          teams_url: 'https://api.github.com/repos/test/test/branches/test_branch/protection/restrictions/teams',
          url: 'https://api.github.com/repos/test/test/branches/test_branch/protection/restrictions',
          users: [],
          users_url: 'https://api.github.com/repos/test/test/branches/test_branch/protection/restrictions/users'
        }
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

    it 'has the ConfigItem branch' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :branch))
    end

    it 'has the ConfigItem github_token' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :github_token))
    end
  end
end
