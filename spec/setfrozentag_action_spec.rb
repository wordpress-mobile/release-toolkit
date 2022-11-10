require 'spec_helper'
require 'shared_examples_for_actions_with_github_token'

describe Fastlane::Actions::SetfrozentagAction do
  let(:test_repository) { 'test-repository' }
  let(:test_token) { 'Test-GithubToken-1234' }
  let(:test_milestone) do
    { title: '10.1', number: '1234' }
  end
  let(:default_params) do
    {
      repository: test_repository,
      milestone: test_milestone[:title],
      freeze: true,
      github_token: 'Test-GithubToken-1234'
    }
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

  it 'raises an error when the milestone is not found or does not exist' do
    allow(client).to receive(:list_milestones).and_return([])
    expect { run_described_fastlane_action(default_params) }.to raise_error(FastlaneCore::Interface::FastlaneError, 'Milestone 10.1 not found.')
  end

  it 'freezes the milestone adding ❄️ to the title' do
    expect(client).to receive(:update_milestone).with(test_repository, test_milestone[:number], title: '10.1 ❄️')
    run_action_with(freeze: true)
  end

  it 'remove any existing ❄️ emoji from a frozen milestone' do
    allow(client).to receive(:list_milestones).and_return([{ title: '10.2 ❄️', number: '1234' }])
    expect(client).to receive(:update_milestone).with(test_repository, test_milestone[:number], title: '10.2')
    run_action_with(freeze: false, milestone: '10.2')
  end

  it 'does not change a milestone that is already frozen' do
    allow(client).to receive(:list_milestones).and_return([{ title: '10.2 ❄️', number: '1234' }])
    expect(client).not_to receive(:update_milestone)
    run_action_with(milestone: '10.2 ❄️')
  end

  it 'does not change an unfrozen milestone if :freeze parameter is false' do
    expect(client).to receive(:update_milestone).with(test_repository, test_milestone[:number], title: '10.1')
    run_action_with(freeze: false)
  end

  describe 'initialize' do
    include_examples 'github_token_initialization'
  end

  describe 'Calling the Action validates input' do
    it 'raises an error if no `GHHELPER_REPOSITORY` environment variable nor parameter `:repository` is present' do
      expect { run_action_without(:repository) }.to raise_error(FastlaneCore::Interface::FastlaneError, "No value found for 'repository'")
    end

    it 'raises an error if no `GHHELPER_MILESTORE` environment variable nor parameter `:milestone` is present' do
      expect { run_action_without(:milestone) }.to raise_error(FastlaneCore::Interface::FastlaneError, "No value found for 'milestone'")
    end

    it 'raises an error if `:freeze` parameter is passed as String' do
      expect { run_action_with(freeze: 'foo') }.to raise_error "'freeze' value must be either `true` or `false`! Found String instead."
    end

    it 'raises an error if `:milestone` parameter is passed as Integer' do
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
