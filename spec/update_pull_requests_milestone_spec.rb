require 'spec_helper'

describe Fastlane::Actions::UpdatePullRequestsMilestoneAction do
  let(:test_token) { 'ghp_fake_token' }
  let(:test_repo) { 'repo-test/project-test' }
  let(:client) do
    instance_double(
      Octokit::Client,
      user: instance_double('User', name: 'test'),
      list_milestones: %w[12.2 12.3 12.4].map { |version| mock_milestone(version) },
      'auto_paginate=': nil
    )
  end

  def mock_milestone(version)
    number = version.to_s.gsub('.', '').to_i
    sawyer_resource_stub(title: "#{version} Fake milestone (##{number})", number: number)
  end

  def mock_pr(number)
    sawyer_resource_stub(number: number)
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(client)
  end

  context 'when providing explicit PR numbers' do
    it 'updates the milestone of a single PR' do
      expect(client).to receive(:update_issue).with(test_repo, 1337, { milestone: 123 })

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        pr_numbers: [1337],
        to_milestone: '12.3'
      )

      expect(result).to eq([1337])
    end

    it 'updates the milestone of provided PRs' do
      expect(client).to receive(:update_issue).with(test_repo, 42, { milestone: 123 })
      expect(client).to receive(:update_issue).with(test_repo, 1337, { milestone: 123 })

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        pr_numbers: [42, 1337],
        to_milestone: '12.3'
      )

      expect(result).to eq([42, 1337])
    end

    it 'removes the milestone if to_milestone is nil' do
      expect(client).to receive(:update_issue).with(test_repo, 1337, { milestone: nil })

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        pr_numbers: [1337],
        to_milestone: nil
      )

      expect(result).to eq([1337])
    end
  end

  context 'when providing a source milestone' do
    it 'updates the milestone of all matching and still-opened PRs' do
      allow(client).to receive(:search_issues)
        .with(%(repo:#{test_repo} type:pr milestone:"#{mock_milestone(12.2)[:title]}" is:open))
        .and_return({ items: [101, 103].map { |n| mock_pr(n) } })

      expect(client).to receive(:update_issue).with(test_repo, 101, { milestone: 123 })
      expect(client).to receive(:update_issue).with(test_repo, 103, { milestone: 123 })

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        from_milestone: '12.2',
        to_milestone: '12.3'
      )

      expect(result).to eq([101, 103])
    end

    it 'adds a PR comment if one is provided' do
      comment = 'Updated milestone from 12.2 to 12.3'
      allow(client).to receive(:search_issues)
        .with(%(repo:#{test_repo} type:pr milestone:"#{mock_milestone(12.2)[:title]}" is:open))
        .and_return({ items: [101, 103].map { |n| mock_pr(n) } })
      allow(client).to receive(:issue_comments).and_return([])

      expect(client).to receive(:update_issue).with(test_repo, 101, { milestone: 123 })
      expect(client).to receive(:add_comment).with(test_repo, 101, /<!-- REUSE_ID: .* -->#{comment}/)
      expect(client).to receive(:update_issue).with(test_repo, 103, { milestone: 123 })
      expect(client).to receive(:add_comment).with(test_repo, 103, /<!-- REUSE_ID: .* -->#{comment}/)

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        from_milestone: '12.2',
        to_milestone: '12.3',
        pr_comment: comment
      )

      expect(result).to eq([101, 103])
    end

    it 'does not add a PR comment if comment is empty' do
      allow(client).to receive(:search_issues)
        .with(%(repo:#{test_repo} type:pr milestone:"#{mock_milestone(12.2)[:title]}" is:open))
        .and_return({ items: [101, 103].map { |n| mock_pr(n) } })

      expect(client).to receive(:update_issue).with(test_repo, 101, { milestone: 123 })
      expect(client).to receive(:update_issue).with(test_repo, 103, { milestone: 123 })
      expect(client).not_to receive(:add_comment)

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        from_milestone: '12.2',
        to_milestone: '12.3',
        pr_comment: ''
      )

      expect(result).to eq([101, 103])
    end
  end

  describe 'error handling' do
    it 'raises a user_error! if the destination milestone could not be found' do
      expect do
        run_described_fastlane_action(
          github_token: test_token,
          repository: test_repo,
          from_milestone: '12.2',
          to_milestone: '99.9'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'Unable to find target milestone matching version 99.9')
    end

    it 'raises if both from_milestone and pr_numbers were provided' do
      expect do
        run_described_fastlane_action(
          github_token: test_token,
          repository: test_repo,
          from_milestone: '12.2',
          pr_numbers: [1337],
          to_milestone: '12.3'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, %(Unresolved conflict between options: 'from_milestone' and 'pr_numbers'))
    end

    it 'raises if neither from_milestone nor pr_numbers were provided' do
      expect do
        run_described_fastlane_action(
          github_token: test_token,
          repository: test_repo,
          to_milestone: '12.3'
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, 'One of `pr_numbers` or `from_milestone` must be provided to indicate which PR(s) to update')
    end
  end
end
