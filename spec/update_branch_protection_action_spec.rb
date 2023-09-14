require 'spec_helper'
require 'tmpdir'

describe Fastlane::Actions::UpdateBranchProtectionAction do
  let(:repo) { 'automattic/demorepo' }
  let(:branch) { 'release/12.3' }
  let(:restrictions) { { users: [], teams: [] } }
  let(:client) do
    instance_double(
      Octokit::Client,
      user: instance_double('User', name: 'test'),
      'auto_paginate=': nil
    )
  end

  def fixture(file)
    path = File.join(File.dirname(__FILE__), 'test-data', 'github_branch_protection', file)
    JSON.parse(File.read(path), symbolize_names: true)
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(client)
  end

  shared_examples('no protection was initially set') do |additional_options = {}|
    it 'uses the default protection settings if no setting is provided explicitly' do
      expected_options = {
        enforce_admins: nil,
        required_pull_request_reviews: {
          dismiss_stale_reviews: false,
          require_code_owner_reviews: false
        },
        restrictions: restrictions
      }

      expect(client).to receive(:protect_branch).with(repo, branch, expected_options)

      run_described_fastlane_action(
        repository: repo,
        branch: branch,
        **additional_options
      )
    end

    it 'unsets `required_status_checks` when an empty `required_ci_checks` is provided' do
      expected_options = {
        required_status_checks: nil,
        enforce_admins: nil,
        required_pull_request_reviews: {
          dismiss_stale_reviews: false,
          require_code_owner_reviews: false
        },
        restrictions: restrictions
      }

      expect(client).to receive(:protect_branch).with(repo, branch, expected_options)

      run_described_fastlane_action(
        repository: repo,
        branch: branch,
        required_ci_checks: [],
        **additional_options
      )
    end

    it 'overrides `required_status_checks` when `required_ci_checks` param is provided' do
      expected_options = {
        required_status_checks: {
          strict: false,
          checks: [
            { context: 'check1' },
            { context: 'check2' },
            { context: 'check3' },
          ]
        },
        enforce_admins: nil,
        required_pull_request_reviews: {
          dismiss_stale_reviews: false,
          require_code_owner_reviews: false
        },
        restrictions: restrictions
      }

      expect(client).to receive(:protect_branch).with(repo, branch, expected_options)

      run_described_fastlane_action(
        repository: repo,
        branch: branch,
        required_ci_checks: %w[check1 check2 check3],
        **additional_options
      )
    end

    it 'overrides `required_approving_review_count` when param is provided' do
      expected_options = {
        enforce_admins: nil,
        required_pull_request_reviews: {
          dismiss_stale_reviews: false,
          require_code_owner_reviews: false,
          required_approving_review_count: 3
        },
        restrictions: restrictions
      }

      expect(client).to receive(:protect_branch).with(repo, branch, expected_options)

      run_described_fastlane_action(
        repository: repo,
        branch: branch,
        required_approving_review_count: 3,
        **additional_options
      )
    end

    it 'overrides `enforce_admins` setting when param is provided' do
      expected_options = {
        enforce_admins: true,
        required_pull_request_reviews: {
          dismiss_stale_reviews: false,
          require_code_owner_reviews: false
        },
        restrictions: restrictions
      }

      expect(client).to receive(:protect_branch).with(repo, branch, expected_options)

      run_described_fastlane_action(
        repository: repo,
        branch: branch,
        enforce_admins: true,
        **additional_options
      )
    end

    it 'overrides `allow_force_pushes` setting when param is provided' do
      expected_options = {
        enforce_admins: nil,
        required_pull_request_reviews: {
          dismiss_stale_reviews: false,
          require_code_owner_reviews: false
        },
        restrictions: restrictions,
        allow_force_pushes: true
      }

      expect(client).to receive(:protect_branch).with(repo, branch, expected_options)

      run_described_fastlane_action(
        repository: repo,
        branch: branch,
        allow_force_pushes: true,
        **additional_options
      )
    end

    it 'overrides `lock_branch` setting when param is provided' do
      expected_options = {
        enforce_admins: nil,
        required_pull_request_reviews: {
          dismiss_stale_reviews: false,
          require_code_owner_reviews: false
        },
        restrictions: restrictions,
        lock_branch: true
      }

      expect(client).to receive(:protect_branch).with(repo, branch, expected_options)

      run_described_fastlane_action(
        repository: repo,
        branch: branch,
        lock_branch: true,
        **additional_options
      )
    end
  end

  context 'when the branch is not protected yet' do
    before do
      allow(client).to receive(:branch_protection).with(repo, branch).and_return(nil)
    end

    it_behaves_like 'no protection was initially set'
  end

  context 'when the branch was protected but `keep_existing_settings_unchanged` is false' do
    before do
      existing_settings = fixture('existing_branch_protection.json')
      allow(client).to receive(:branch_protection).with(repo, branch).and_return(existing_settings)
    end

    it_behaves_like 'no protection was initially set', keep_existing_settings_unchanged: false
  end

  context 'when the branch was protected and `keep_existing_settings_unchanged` is true' do
    before do
      allow(client).to receive(:branch_protection)
        .with(repo, branch)
        .and_return(fixture('existing_branch_protection.json'))
    end

    let(:existing_settings) do
      {
        allow_deletions: true,
        allow_force_pushes: true,
        allow_fork_syncing: true,
        block_creations: true,
        enforce_admins: true,
        lock_branch: true,
        required_conversation_resolution: true,
        required_linear_history: true,
        required_pull_request_reviews: {
          dismiss_stale_reviews: true,
          dismissal_restrictions: { apps: [], teams: [], users: [] },
          require_code_owner_reviews: true,
          require_last_push_approval: true,
          required_approving_review_count: 2
        },
        required_signatures: false,
        required_status_checks: {
          strict: true,
          checks: [
            { context: 'buildkite/check1', app_id: nil },
            { context: 'buildkite/check2', app_id: nil },
          ]
        },
        restrictions: { apps: [], teams: ['the-power-team'], users: ['release-toolkit-user'] }
      }
    end

    it 'keeps the existing protection settings if no setting is provided explicitly' do
      expect(client).to receive(:protect_branch).with(repo, branch, existing_settings)

      run_described_fastlane_action(
        repository: repo,
        branch: branch
      )
    end

    it 'unsets `required_status_checks` when an empty `required_ci_checks` is provided' do
      expected_options = existing_settings.dup
      expected_options[:required_status_checks] = nil

      expect(client).to receive(:protect_branch).with(repo, branch, expected_options)

      run_described_fastlane_action(
        repository: repo,
        branch: branch,
        required_ci_checks: []
      )
    end

    it 'overrides `required_status_checks` when `required_ci_checks` param is provided' do
      expected_options = existing_settings.dup
      expected_options[:required_status_checks][:checks] = [
        { context: 'new/check1' },
        { context: 'new/check2' },
        { context: 'new/check3' },
      ]

      expect(client).to receive(:protect_branch).with(repo, branch, expected_options)

      run_described_fastlane_action(
        repository: repo,
        branch: branch,
        required_ci_checks: %w[new/check1 new/check2 new/check3]
      )
    end

    it 'overrides `required_approving_review_count` when param is provided' do
      expect(existing_settings[:required_pull_request_reviews][:required_approving_review_count]).not_to eq(3)
      expected_options = existing_settings.dup
      expected_options[:required_pull_request_reviews][:required_approving_review_count] = 3

      expect(client).to receive(:protect_branch).with(repo, branch, expected_options)

      run_described_fastlane_action(
        repository: repo,
        branch: branch,
        required_approving_review_count: 3
      )
    end

    it 'overrides `enforce_admins` setting when param is provided' do
      expect(existing_settings[:enforce_admins]).to be(true)
      expected_options = existing_settings.dup
      expected_options[:enforce_admins] = false

      expect(client).to receive(:protect_branch).with(repo, branch, expected_options)

      run_described_fastlane_action(
        repository: repo,
        branch: branch,
        enforce_admins: false
      )
    end

    it 'overrides `allow_force_pushes` setting when param is provided' do
      expect(existing_settings[:allow_force_pushes]).to be(true)
      expected_options = existing_settings.dup
      expected_options[:allow_force_pushes] = false

      expect(client).to receive(:protect_branch).with(repo, branch, expected_options)

      run_described_fastlane_action(
        repository: repo,
        branch: branch,
        allow_force_pushes: false
      )
    end

    it 'overrides `lock_branch` setting when param is provided' do
      expect(existing_settings[:lock_branch]).to be(true)
      expected_options = existing_settings.dup
      expected_options[:lock_branch] = false

      expect(client).to receive(:protect_branch).with(repo, branch, expected_options)

      run_described_fastlane_action(
        repository: repo,
        branch: branch,
        lock_branch: false
      )
    end
  end
end
