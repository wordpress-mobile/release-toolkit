# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::FindOrCreatePullRequestAction do
  let(:test_token) { 'ghp_fake_token' }
  let(:test_repo) { 'repo-test/project-test' }
  let(:test_head) { 'translations/daily-update' }
  let(:test_base) { 'trunk' }
  let(:github_helper) { instance_double(Fastlane::Helper::GithubHelper) }
  let(:other_action_mock) { double }

  before do
    allow(Fastlane::Helper::GithubHelper).to receive(:new).with(github_token: test_token).and_return(github_helper)
    allow(Fastlane::Action).to receive(:other_action).and_return(other_action_mock)
  end

  context 'when an open PR already exists for the head branch' do
    it 'returns its URL and does not create a new PR' do
      existing_pr = double('PullRequest', html_url: "https://github.com/#{test_repo}/pull/7") # rubocop:disable RSpec/VerifiedDoubles
      allow(github_helper).to receive(:find_pull_request)
        .with(repository: test_repo, head: test_head, base: test_base)
        .and_return(existing_pr)
      expect(other_action_mock).not_to receive(:create_pull_request)

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        title: 'Update translations',
        head: test_head,
        base: test_base
      )

      expect(result).to eq("https://github.com/#{test_repo}/pull/7")
    end
  end

  context 'when no open PR exists for the head branch' do
    it 'creates a new PR forwarding the parameters and returns its URL' do
      allow(github_helper).to receive(:find_pull_request).and_return(nil)
      allow(other_action_mock).to receive(:create_pull_request).with(
        api_url: 'https://api.github.com',
        api_token: test_token,
        repo: test_repo,
        title: 'Update translations',
        body: 'Sync translations from GlotPress',
        draft: nil,
        head: test_head,
        base: test_base,
        labels: ['Localization'],
        assignees: nil,
        reviewers: nil,
        team_reviewers: nil,
        milestone: nil
      ).and_return("https://github.com/#{test_repo}/pull/8")

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        title: 'Update translations',
        body: 'Sync translations from GlotPress',
        head: test_head,
        base: test_base,
        labels: ['Localization']
      )

      expect(result).to eq("https://github.com/#{test_repo}/pull/8")
    end

    it 'forwards draft: true when creating a draft PR' do
      allow(github_helper).to receive(:find_pull_request).and_return(nil)
      allow(other_action_mock).to receive(:create_pull_request)
        .with(hash_including(draft: true))
        .and_return("https://github.com/#{test_repo}/pull/9")

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        title: 'Update translations',
        head: test_head,
        base: test_base,
        draft: true
      )

      expect(result).to eq("https://github.com/#{test_repo}/pull/9")
    end
  end
end
