require 'spec_helper'

describe Fastlane::Actions::PublishGithubReleaseAction do
  let(:test_token) { 'ghp_fake_token' }
  let(:test_repo) { 'repo-test/project-test' }
  let(:test_name) { '1.0.0' }
  let(:github_helper) { instance_double(Fastlane::Helper::GithubHelper) }

  before do
    allow(Fastlane::Helper::GithubHelper).to receive(:new).and_return(github_helper)
  end

  context 'when providing valid parameters' do
    it 'publishes the release and returns the URL' do
      allow(github_helper).to receive(:publish_release).with(
        repository: test_repo,
        name: test_name,
        prerelease: nil
      ).and_return('https://github.com/repo-test/project-test/releases/tag/1.0.0')

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        name: test_name
      )

      expect(result).to eq('https://github.com/repo-test/project-test/releases/tag/1.0.0')
    end

    it 'publishes a prerelease when specified' do
      allow(github_helper).to receive(:publish_release).with(
        repository: test_repo,
        name: test_name,
        prerelease: true
      ).and_return('https://github.com/repo-test/project-test/releases/tag/1.0.0-beta')

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        name: test_name,
        prerelease: true
      )

      expect(result).to eq('https://github.com/repo-test/project-test/releases/tag/1.0.0-beta')
    end
  end

  context 'when successful' do
    it 'prints a success message' do
      allow(github_helper).to receive(:publish_release).and_return('https://github.com/repo-test/project-test/releases/tag/1.0.0')

      allow(Fastlane::UI).to receive(:success).with(anything).at_least(:once)
      expect(Fastlane::UI).to receive(:success).with("Successfully published GitHub Release 1.0.0. You can see it at 'https://github.com/repo-test/project-test/releases/tag/1.0.0'")

      run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        name: test_name
      )
    end
  end
end
