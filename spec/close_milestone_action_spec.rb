require 'spec_helper'
require 'shared_examples_for_actions_with_github_token'

describe Fastlane::Actions::CloseMilestoneAction do
  let(:test_repository) { 'test-repository' }
  let(:test_token) { 'Test-GithubToken-1234' }
  let(:test_milestone) do
    { title: '10.1', number: '1234' }
  end
  let(:default_params) do
    { repository: test_repository,
      milestone: test_milestone[:title],
      github_token: 'Test-GithubToken-1234' }
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

  it 'closes the expected milestone on the expected repository' do
    expect(client).to receive(:update_milestone).with(test_repository, test_milestone[:number], state: 'closed')
    run_described_fastlane_action(default_params)
  end

  it 'raises an error when the milestone is not found or does not exist' do
    allow(client).to receive(:list_milestones).and_return([])
    expect { run_described_fastlane_action(default_params) }.to raise_error(FastlaneCore::Interface::FastlaneError, 'Milestone 10.1 not found.')
  end

  describe 'initialize' do
    include_examples 'github_token_initialization'
  end

  describe 'calling the action validates input' do
    it 'raises an error if no `GHHELPER_REPOSITORY` environment variable nor parameter `:repository` is present' do
      expect { run_action_without(:repository) }.to raise_error(FastlaneCore::Interface::FastlaneError, "No value found for 'repository'")
    end

    it 'raises an error if no `GHHELPER_MILESTONE` environment variable nor parameter `:milestone` is present' do
      expect { run_action_without(:milestone) }.to raise_error(FastlaneCore::Interface::FastlaneError, "No value found for 'milestone'")
    end

    it 'raises an error if `milestone:` parameter is passed as Integer' do
      expect { run_action_with(milestone: 10) }.to raise_error "'milestone' value must be a String! Found Integer instead."
    end
  end

  def run_action_with(**keys_and_values)
    params = default_params.merge(keys_and_values)
    run_described_fastlane_action(params)
  end

  def run_action_without(key)
    run_described_fastlane_action(default_params.except(key))
  end
end
