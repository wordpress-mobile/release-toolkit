require 'spec_helper'

describe Fastlane::Actions::CreateReleaseBackmergePullRequestAction do
  let(:test_token) { 'ghp_fake_token' }
  let(:test_repo) { 'repo-test/project-test' }
  let(:default_branch) { 'main' }
  let(:other_action_mock) { double }
  let(:client) do
    instance_double(
      Octokit::Client,
      user: instance_double('User', name: 'test'),
      list_milestones: %w[30.7 30.6 30.5 30.5.1 30.4].map { |version| mock_milestone(version) },
      'auto_paginate=': nil
    )
  end
  let(:git_client) { instance_double(Git::Base) }

  def mock_milestone(release_branch)
    release_version = release_branch.delete('release/')
    number = release_version.gsub('.', '').to_i
    sawyer_resource_stub(title: release_version, number: number)
  end

  def mock_pr_url(release_branch)
    number = release_branch.delete('release/').gsub('.', '').to_i
    "https://github.com/#{test_repo}/pull/#{number}"
  end

  def stub_git_release_branches(branches)
    allow(Fastlane::Actions).to receive(:sh)
      .with('git', 'branch', '-r', '-l', 'origin/release/*')
      .and_return("\n" + branches.map { |release| "origin/#{release}" }.join("\n") + "\n")

    allow(git_client).to receive(:branches).and_return(
      branches.map { |b| instance_double(Git::Branch, remote: instance_double(Git::Remote, name: 'origin'), name: b) }
    )
  end

  def stub_expected_pull_requests(expected_backmerge_branches:, source_branch:, labels: [], milestone_number: nil, reviewers: nil, team_reviewers: nil, branch_exists_on_remote: false, point_to_same_commit: false)
    expected_backmerge_branches.map do |target_branch|
      expected_intermediate_branch = "merge/#{source_branch.gsub('/', '-')}-into-#{target_branch.gsub('/', '-')}"

      allow(Fastlane::Helper::GitHelper).to receive(:branch_exists_on_remote?).with(branch_name: expected_intermediate_branch).and_return(branch_exists_on_remote)

      allow(Fastlane::Helper::GitHelper).to receive(:point_to_same_commit?).with(target_branch, source_branch).and_return(point_to_same_commit)

      next if point_to_same_commit

      expect(Fastlane::Helper::GitHelper).to receive(:checkout_and_pull).with(source_branch)
      expect(Fastlane::Helper::GitHelper).to receive(:create_branch).with(expected_intermediate_branch)
      expect(other_action_mock).to receive(:push_to_git_remote).with(tags: false)

      allow(other_action_mock).to receive(:create_pull_request).with(
        api_token: test_token,
        repo: test_repo,
        title: "Merge #{source_branch} into #{target_branch}",
        body: anything,
        head: expected_intermediate_branch,
        base: target_branch,
        labels: labels,
        milestone: milestone_number,
        reviewers: reviewers,
        team_reviewers: team_reviewers
      ).and_return(mock_pr_url(target_branch))

      expected_intermediate_branch
    end
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(client)
    allow(Fastlane::Helper::GitHelper).to receive(:checkout_and_pull)
    allow(Fastlane::Helper::GitHelper).to receive(:create_branch)
    allow(Fastlane::Helper::GitHelper).to receive(:delete_local_branch_if_exists!)
    allow(Fastlane::Helper::GitHelper).to receive(:delete_remote_branch_if_exists!)
    allow(Git).to receive(:open).and_return(git_client)
    allow(Fastlane::Action).to receive(:other_action).and_return(other_action_mock)
  end

  context 'when `target_branches` is provided' do
    it 'creates a backmerge PR for each target branch' do
      # all release branches should be ignored as we're providing `target_branches`
      stub_git_release_branches(%w[release/30.5 release/30.6 release/30.7 release/30.8])

      source_branch = 'release/30.7'

      expected_backmerge_branches = %w[trunk release/30.6]
      stub_expected_pull_requests(
        expected_backmerge_branches: expected_backmerge_branches,
        source_branch: source_branch
      )

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        source_branch: source_branch,
        target_branches: expected_backmerge_branches
      )

      expect(result).to eq(expected_backmerge_branches.map { |target_branch| mock_pr_url(target_branch) })
    end
  end

  context 'when `target_branches` is not provided' do
    it 'determines target branches and creates backmerge PRs' do
      # only release branches with version > `source_branch` should have a backmerge created
      stub_git_release_branches(%w[release/30.6 release/30.5.1 release/30.5 release/30.4])

      source_branch = 'release/30.5'

      expected_backmerge_branches = %w[release/30.6 release/30.5.1]
      stub_expected_pull_requests(
        expected_backmerge_branches: expected_backmerge_branches,
        source_branch: source_branch
      )

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        source_branch: source_branch
      )

      expect(result).to eq(expected_backmerge_branches.map { |target_branch| mock_pr_url(target_branch) })
    end

    it 'defaults to the `default_branch` if no newer release branches are found' do
      stub_git_release_branches(%w[release/30.6 release/30.5])

      source_branch = 'release/30.6'

      stub_expected_pull_requests(
        expected_backmerge_branches: [default_branch],
        source_branch: source_branch
      )

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        source_branch: source_branch,
        default_branch: default_branch
      )

      expect(result).to eq([mock_pr_url(default_branch)])
    end
  end

  context 'when providing invalid input' do
    it 'throws an error when the `source_branch` is invalid' do
      stub_git_release_branches([])

      source_branch = '30.6'

      expect do
        run_described_fastlane_action(
          github_token: test_token,
          repository: test_repo,
          source_branch: source_branch,
          default_branch: default_branch
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, '`source_branch` must start with `release/`')
    end

    it 'throws an error when the `source_branch` in one of the `target_branches`' do
      stub_git_release_branches([])

      source_branch = 'release/30.6'

      expect do
        run_described_fastlane_action(
          github_token: test_token,
          repository: test_repo,
          source_branch: source_branch,
          default_branch: default_branch,
          target_branches: ['release/30.6.1', 'release/30.6', 'release/30.7']
        )
      end.to raise_error(FastlaneCore::Interface::FastlaneError, '`target_branches` must not contain `source_branch`')
    end
  end

  context 'when providing a milestone' do
    it 'creates a backmerge PR setting a milestone' do
      stub_git_release_branches([])

      source_branch = 'release/30.6'
      milestone = mock_milestone(source_branch)

      stub_expected_pull_requests(
        expected_backmerge_branches: [default_branch],
        source_branch: source_branch,
        milestone_number: milestone[:number]
      )

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        source_branch: source_branch,
        default_branch: default_branch,
        milestone_title: milestone[:title]
      )

      expect(result).to eq([mock_pr_url(default_branch)])
    end

    it 'no milestone is set if an unknown milestone is used' do
      stub_git_release_branches([])

      source_branch = 'release/30.7'

      stub_expected_pull_requests(
        expected_backmerge_branches: [default_branch],
        source_branch: source_branch,
        milestone_number: nil
      )

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        source_branch: source_branch,
        default_branch: default_branch,
        milestone_title: 'nonexistentmilestone'
      )

      expect(result).to eq([mock_pr_url(default_branch)])
    end
  end

  context 'when providing labels' do
    [
      %w[java ruby perl],
      [],
    ].each do |labels|
      it "creates a backmerge PR setting the labels: #{labels}" do
        stub_git_release_branches([])

        source_branch = 'release/30.6'

        stub_expected_pull_requests(
          expected_backmerge_branches: [default_branch],
          source_branch: source_branch,
          labels: labels
        )

        result = run_described_fastlane_action(
          github_token: test_token,
          repository: test_repo,
          source_branch: source_branch,
          default_branch: default_branch,
          labels: labels
        )

        expect(result).to eq([mock_pr_url(default_branch)])
      end
    end
  end

  context 'when providing reviewers' do
    [
      { team_reviewers: %w[team_awesome team_a], reviewers: %w[coder rubyist] },
      { team_reviewers: nil, reviewers: nil },
    ].each do |reviewers|
      it "creates a backmerge PR setting the team_reviewers `#{reviewers[:team_reviewers]}` and reviewers `#{reviewers[:reviewers]}`" do
        stub_git_release_branches([])

        source_branch = 'release/30.6'

        stub_expected_pull_requests(
          expected_backmerge_branches: [default_branch],
          source_branch: source_branch,
          reviewers: reviewers[:reviewers],
          team_reviewers: reviewers[:team_reviewers]
        )

        result = run_described_fastlane_action(
          github_token: test_token,
          repository: test_repo,
          source_branch: source_branch,
          default_branch: default_branch,
          reviewers: reviewers[:reviewers],
          team_reviewers: reviewers[:team_reviewers]
        )

        expect(result).to eq([mock_pr_url(default_branch)])
      end
    end
  end

  context 'when checking if source & target branches point to the same commit' do
    it 'does not create a pull request when `source_branch` a target branch point to the same commit' do
      stub_git_release_branches(%w[release/30.6])

      source_branch = 'release/30.7'

      expected_backmerge_branches = %w[trunk release/30.6]
      stub_expected_pull_requests(
        expected_backmerge_branches: expected_backmerge_branches,
        source_branch: source_branch,
        point_to_same_commit: true
      )

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        source_branch: source_branch,
        target_branches: expected_backmerge_branches
      )

      expect(result).to be_empty
    end
  end

  context 'when the branch already exists' do
    it 'delete the branch before creating it anew' do
      stub_git_release_branches(%w[release/30.7])

      source_branch = 'release/30.7'

      intermediate_branches = stub_expected_pull_requests(
        expected_backmerge_branches: [default_branch],
        source_branch: source_branch,
        branch_exists_on_remote: true
      )

      intermediate_branches.each do |branch|
        expect(FastlaneCore::UI).to receive(:important)
          .with("An intermediate branch `#{branch}` already exists on the remote. It will be deleted and GitHub will close any associated existing PR.")
        expect(Fastlane::Helper::GitHelper).to receive(:delete_remote_branch_if_exists!).with(branch)
        expect(Fastlane::Helper::GitHelper).to receive(:delete_local_branch_if_exists!).with(branch)
      end

      result = run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        source_branch: source_branch,
        default_branch: default_branch
      )

      expect(result).to eq([mock_pr_url(default_branch)])
    end
  end

  context 'when using the `intermediate_branch_created_callback` callback' do
    it 'correctly calls the callback when there is one' do
      stub_git_release_branches([])

      source_branch = 'release/30.6'

      stub_expected_pull_requests(
        expected_backmerge_branches: [default_branch],
        source_branch: source_branch
      )

      intermediate_branch = "merge/release-30.6-into-#{default_branch}"
      expect(other_action_mock).to receive(:ensure_git_branch).with(branch: "^#{intermediate_branch}/")
      allow(Fastlane::UI).to receive(:message).with(anything)
      expect(Fastlane::UI).to receive(:message).with("branch created callback was called! #{default_branch} #{intermediate_branch}")

      # Due to the Proc parameter, we cannot use run_described_fastlane_action as it converts everything to strings
      lane = <<~LANE
        lane :test_branch_created_callback do
          #{described_class.action_name}(
            github_token: '#{test_token}',
            repository: '#{test_repo}',
            source_branch: '#{source_branch}',
            default_branch: '#{default_branch}',
            intermediate_branch_created_callback: proc { |target, intermediate_branch| UI.message('branch created callback was called! ' + target + ' ' + intermediate_branch) }
          )
        end
      LANE
      Fastlane::FastFile.new.parse(lane).runner.execute(:test_branch_created_callback)
    end
  end
end
