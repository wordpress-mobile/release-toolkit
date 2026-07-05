# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Actions::UploadGithubReleaseAssetsAction do
  let(:test_token) { 'ghp_fake_token' }
  let(:test_repo) { 'repo-test/project-test' }
  let(:test_version) { '1.0.0' }
  let(:test_assets) { ['builds/test-app.zip'] }
  let(:test_url) { 'https://github.com/repo-test/project-test/releases/tag/1.0.0' }
  let(:github_helper) { instance_double(Fastlane::Helper::GithubHelper) }

  before do
    allow(Fastlane::Helper::GithubHelper).to receive(:new).with(github_token: test_token).and_return(github_helper)
  end

  it 'uploads release assets and returns the release URL' do
    allow(github_helper).to receive(:upload_release_assets).and_return(test_url)
    expect(github_helper).to receive(:upload_release_assets).with(
      repository: test_repo,
      version: test_version,
      assets: test_assets,
      replace_existing: true
    )

    result = run_described_fastlane_action(
      github_token: test_token,
      repository: test_repo,
      version: test_version,
      release_assets: test_assets
    )

    expect(result).to eq(test_url)
  end

  it 'forwards replace_existing when provided' do
    allow(github_helper).to receive(:upload_release_assets).and_return(test_url)
    expect(github_helper).to receive(:upload_release_assets).with(
      repository: test_repo,
      version: test_version,
      assets: test_assets,
      replace_existing: false
    )

    result = run_described_fastlane_action(
      github_token: test_token,
      repository: test_repo,
      version: test_version,
      release_assets: test_assets,
      replace_existing: false
    )

    expect(result).to eq(test_url)
  end

  it 'fails when release_assets is empty' do
    expect do
      run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        version: test_version,
        release_assets: []
      )
    end.to raise_error(FastlaneCore::Interface::FastlaneError, 'You must provide at least one release asset')
  end

  it 'fails when release_assets contains a non-path value' do
    expect do
      run_described_fastlane_action(
        github_token: test_token,
        repository: test_repo,
        version: test_version,
        release_assets: [123]
      )
    end.to raise_error(FastlaneCore::Interface::FastlaneError, 'release_assets must contain file paths')
  end
end
