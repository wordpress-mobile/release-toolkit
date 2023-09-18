require 'spec_helper'
require 'tmpdir'

describe Fastlane::Actions::RemoveBranchProtectionAction do
  let(:repo) { 'automattic/demorepo' }
  let(:branch) { 'release/12.3' }
  let(:github_token) { 'stubbed-gh-token' }
  let(:client) do
    instance_double(
      Octokit::Client,
      user: instance_double('User', name: 'test'),
      'auto_paginate=': nil
    )
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(client)
  end

  it 'removes branch protection if the branch was protected' do
    expect(client).to receive(:unprotect_branch).with(repo, branch)

    run_described_fastlane_action(
      repository: repo,
      branch: branch,
      github_token: github_token
    )
  end

  it 'does nothing if the branch was not protected in the first place' do
    allow(client).to receive(:unprotect_branch).with(repo, branch).and_raise(Octokit::BranchNotProtected)
    expect(client).to receive(:unprotect_branch).with(repo, branch)

    allow(FastlaneCore::UI).to receive(:message)
    expect(FastlaneCore::UI).to receive(:message).with("Note: Branch `#{branch}` was not protected in the first place.")

    run_described_fastlane_action(
      repository: repo,
      branch: branch,
      github_token: github_token
    )
  end

  it 'reports an error if the branch does not exist' do
    allow(client).to receive(:unprotect_branch).with(repo, branch).and_raise(Octokit::NotFound)
    expect(client).to receive(:unprotect_branch).with(repo, branch)

    expect do
      run_described_fastlane_action(
        repository: repo,
        branch: branch,
        github_token: github_token
      )
    end.to raise_error FastlaneCore::Interface::FastlaneError, "Branch `#{branch}` of repository `#{repo}` was not found."
  end
end
