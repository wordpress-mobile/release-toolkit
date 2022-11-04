require 'spec_helper'

describe Fastlane::Actions::CloseMilestoneAction do
  let(:test_repository) { 'test-repository' }
  let(:test_token) { 'Test-GithubToken-1234' }
  let(:test_milestone) do
    { title: '10.1', number: '1234' }
  end
  let(:client) do
    instance_double(
      Octokit::Client,
      list_milestones: [test_milestone],
      update_milestone: nil,
      user: instance_double('User', name: 'test'),
      'auto_paginate=': nil
    )
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(client)
  end

  it 'properly passes the environment variable `GITHUB_TOKEN` to Octokit::Client' do
    ENV['GITHUB_TOKEN'] = test_token
    expect(Octokit::Client).to receive(:new).with(access_token: test_token)
    run_action_without_key(:github_token)
  end

  it 'properly passes the parameter `:github_token` to Octokit::Client' do
    expect(Octokit::Client).to receive(:new).with(access_token: test_token)
    run_described_fastlane_action(default_params)
  end

  it 'prioritizes `:github_token` parameter over `GITHUB_TOKEN` environment variable if both are present' do
    ENV['GITHUB_TOKEN'] = 'Test-EnvGithubToken-1234'
    expect(Octokit::Client).to receive(:new).with(access_token: test_token)
    run_described_fastlane_action(default_params)
  end

  it 'properly passes the repository and milestone to Octokit::Client to update the milestone as closed' do
    expect(client).to receive(:update_milestone).with(test_repository, test_milestone[:number], state: 'closed')
    run_described_fastlane_action(default_params)
  end

  it 'raises an error when the milestone is not found or does not exist' do
    allow(client).to receive(:list_milestones).and_return([])
    expect { run_described_fastlane_action(default_params) }.to raise_error(FastlaneCore::Interface::FastlaneError, 'Milestone 10.1 not found.')
  end

  describe 'Calling the Action validates input' do
    it 'raises an error if no `GITHUB_TOKEN` environment variable nor parameter `:github_token` is present' do
      ENV['GITHUB_TOKEN'] = nil
      expect { run_action_without_key(:github_token) }.to raise_error(FastlaneCore::Interface::FastlaneError, "No value found for 'github_token'")
    end

    it 'raises an error if no `GHHELPER_REPOSITORY` environment variable nor parameter `:repository` is present' do
      expect { run_action_without_key(:repository) }.to raise_error(FastlaneCore::Interface::FastlaneError, "No value found for 'repository'")
    end

    it 'raises an error if no `GHHELPER_MILESTONE` environment variable nor parameter `:milestone` is present' do
      expect { run_action_without_key(:milestone) }.to raise_error(FastlaneCore::Interface::FastlaneError, "No value found for 'milestone'")
    end

    it 'raises an error if `milestone:` parameter is passed as Integer' do
      expect { run_action_with(:milestone, 10) }.to raise_error "'milestone' value must be a String! Found Integer instead."
    end
  end

  def run_action_without_key(key)
    run_described_fastlane_action(default_params.except(key))
  end

  def run_action_with(key, value)
    values = default_params
    values[key] = value
    run_described_fastlane_action(values)
  end

  def default_params
    {
      repository: test_repository,
      milestone: test_milestone[:title],
      github_token: test_token
    }
  end
end
