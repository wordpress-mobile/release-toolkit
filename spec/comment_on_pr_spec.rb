require 'spec_helper'

describe Fastlane::Actions::CommentOnPrAction do
  describe 'run' do
    let(:test_project) { 'test/test' }
    let(:test_pr_number) { 1234 }
    let(:test_body) { 'Test' }
    let(:test_reuse_identifier) { 'test-id' }
    let(:test_token) { 'GITHUB_TOKEN' }
    let(:github_helper) { class_double(Fastlane::Helper::GithubHelper) }

    before do
      allow(github_helper).to receive(:comment_on_pr).and_return('')
      allow(Fastlane::Helper::GithubHelper).to receive(:new).and_return(github_helper)
    end

    it 'sets the github_token' do
      expect(Fastlane::Helper::GithubHelper).to receive(:new).with(github_token: test_token)
      described_class.run(mock_params)
    end

    it 'calls the comment_on_pr' do
      expect(github_helper).to receive(:comment_on_pr).with(
        project_slug: test_project,
        pr_number: test_pr_number,
        body: test_body,
        reuse_identifier: test_reuse_identifier
      )

      described_class.run(mock_params)
    end

    def mock_params
      {
        project: test_project,
        pr_number: test_pr_number,
        body: test_body,
        reuse_identifier: test_reuse_identifier,
        github_token: test_token
      }
    end
  end

  describe 'available_options' do
    it 'has the correct length' do
      expect(described_class.available_options.length).to be(5)
    end

    it 'has the ConfigItem reuse_identifier' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :reuse_identifier))
    end

    it 'has the ConfigItem project' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :project))
    end

    it 'has the ConfigItem pr_number' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :pr_number))
    end

    it 'has the ConfigItem body' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :body))
    end

    it 'has the ConfigItem github_token' do
      expect(described_class.available_options).to include(an_object_having_attributes(key: :github_token))
    end
  end
end
