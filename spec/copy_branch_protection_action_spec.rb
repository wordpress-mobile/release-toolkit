require 'spec_helper'
require 'tmpdir'

describe Fastlane::Actions::CopyBranchProtectionAction do
  let(:repo) { 'automattic/demorepo' }
  let(:from_branch) { 'trunk' }
  let(:to_branch) { 'release/12.3' }
  let(:github_token) { 'stubbed-gh-token' }
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

  it 'copies the branch protection settings when all parameters are valid' do
    existing_settings = fixture('existing_branch_protection.json')
    allow(client).to receive(:branch_protection).with(repo, from_branch).and_return(sawyer_resource_stub(**existing_settings))

    new_settings = Fastlane::Helper::GithubHelper.branch_protection_api_response_to_normalized_hash(existing_settings)
    expect(client).to receive(:protect_branch).with(repo, to_branch, new_settings)

    run_described_fastlane_action(
      repository: repo,
      from_branch:,
      to_branch:,
      github_token:
    )
  end

  it 'reports an error if the `from_branch` does not exist' do
    allow(client).to receive(:branch_protection).with(repo, from_branch).and_raise(Octokit::NotFound)

    expect do
      run_described_fastlane_action(
        repository: repo,
        from_branch:,
        to_branch:,
        github_token:
      )
    end.to raise_error(FastlaneCore::Interface::FastlaneError, "Branch `#{from_branch}` of repository `#{repo}` was not found.")
  end

  it 'reports an error if the `from_branch` is not protected' do
    allow(client).to receive(:branch_protection).with(repo, from_branch).and_return(nil)

    expect do
      run_described_fastlane_action(
        repository: repo,
        from_branch:,
        to_branch:,
        github_token:
      )
    end.to raise_error(FastlaneCore::Interface::FastlaneError, "Branch `#{from_branch}` does not have any branch protection set up.")
  end

  it 'reports an error if the `to_branch` does not exist' do
    existing_settings = fixture('existing_branch_protection.json')
    allow(client).to receive(:branch_protection).with(repo, from_branch).and_return(sawyer_resource_stub(**existing_settings))
    new_settings = Fastlane::Helper::GithubHelper.branch_protection_api_response_to_normalized_hash(existing_settings)
    allow(client).to receive(:protect_branch).with(repo, to_branch, new_settings).and_raise(Octokit::NotFound)

    expect do
      run_described_fastlane_action(
        repository: repo,
        from_branch:,
        to_branch:,
        github_token:
      )
    end.to raise_error(FastlaneCore::Interface::FastlaneError, "Branch `#{to_branch}` of repository `#{repo}` was not found.")
  end
end
