require 'spec_helper'

describe Fastlane::Actions::CreateNewMilestoneAction do
  let(:test_repository) { 'test-repository' }
  let(:test_token) { 'Test-GithubToken-1234' }
  let(:test_milestone) do
    { title: '10.1', number: '1234', due_on: '2022-10-31T07:00:00Z' }
  end
  let(:milestone_list) do
    [
      { title: '10.2', number: '1234', due_on: '2022-10-31T12:00:00Z' },
      { title: '10.3', number: '4567', due_on: '2022-11-02T15:00:00Z' },
      { title: '10.4', number: '7890', due_on: '2022-11-04T23:59:00Z' },
    ]
  end
  let(:client) do
    instance_double(
      Octokit::Client,
      list_milestones: [test_milestone],
      create_milestone: nil,
      user: instance_double('User', name: 'test'),
      'auto_paginate=': nil
    )
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(client)
  end

  it 'computes the correct due date and milestone description' do
    comment = "Code freeze: November 14, 2022\nApp Store submission: November 28, 2022\nRelease: November 28, 2022\n"
    expect(client).to receive(:create_milestone).with(test_repository, '10.2', due_on: '2022-11-14T12:00:00Z', description: comment)
    run_described_fastlane_action(default_params)
  end

  it 'removes 3 days from the AppStore submission date when `:need_appstore_submission` is true' do
    comment = "Code freeze: November 14, 2022\nApp Store submission: November 25, 2022\nRelease: November 28, 2022\n"
    expect(client).to receive(:create_milestone).with(test_repository, '10.2', due_on: '2022-11-14T12:00:00Z', description: comment)
    run_action_with(:need_appstore_submission, true)
  end

  it 'uses the most recent milestone date to calculate the due date and version of new milestone' do
    comment = "Code freeze: November 18, 2022\nApp Store submission: December 02, 2022\nRelease: December 02, 2022\n"
    allow(client).to receive(:list_milestones).and_return(milestone_list)
    expect(client).to receive(:create_milestone).with(test_repository, '10.5', due_on: '2022-11-18T12:00:00Z', description: comment)
    run_described_fastlane_action(default_params)
  end

  it 'raises an error when the due date of milestone does not exists' do
    allow(client).to receive(:list_milestones).and_return([{ title: '10.1', number: '1234' }])
    expect { run_described_fastlane_action(default_params) }.to raise_error(FastlaneCore::Interface::FastlaneError, 'Milestone 10.1 has no due date.')
  end

  it 'raises an error when the milestone is not found or does not exist on the repository' do
    allow(client).to receive(:list_milestones).and_return([])
    expect { run_described_fastlane_action(default_params) }.to raise_error(FastlaneCore::Interface::FastlaneError, 'No milestone found on the repository.')
  end

  describe 'initialize' do
    context 'with github_token' do
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
    end

    context 'when using default parameters' do
      let(:github_helper) do
        instance_double(
          Fastlane::Helper::GithubHelper,
          get_last_milestone: test_milestone,
          create_milestone: nil
        )
      end

      before do
        allow(Fastlane::Helper::GithubHelper).to receive(:new).and_return(github_helper)
      end

      it 'uses default value when neither `GHHELPER_NUMBER_OF_DAYS_FROM_CODE_FREEZE_TO_RELEASE` environment variable nor parameter `:number_of_days_from_code_freeze_to_release` is present' do
        default_code_freeze_days = 14
        expect(github_helper).to receive(:create_milestone).with(
          anything,
          anything,
          anything,
          anything,
          default_code_freeze_days,
          anything
        )
        run_described_fastlane_action(default_params)
      end

      it 'uses default value when neither `GHHELPER_MILESTONE_DURATION` environment variable nor parameter `:milestone_duration` is present' do
        default_milestone_duration = 14
        expect(github_helper).to receive(:create_milestone).with(
          anything,
          anything,
          anything,
          default_milestone_duration,
          anything,
          anything
        )
        run_described_fastlane_action(default_params)
      end
    end
  end

  describe 'calling the action validates input' do
    it 'raises an error if no `GITHUB_TOKEN` environment variable nor parameter `:github_token` is present' do
      ENV['GITHUB_TOKEN'] = nil
      expect { run_action_without_key(:github_token) }.to raise_error(FastlaneCore::Interface::FastlaneError, "No value found for 'github_token'")
    end

    it 'raises an error if no `GHHELPER_REPOSITORY` environment variable nor parameter `:repository` is present' do
      expect { run_action_without_key(:repository) }.to raise_error(FastlaneCore::Interface::FastlaneError, "No value found for 'repository'")
    end

    it 'raises an error if `need_appstore_submission:` parameter is passed as String' do
      expect { run_action_with(:need_appstore_submission, 'foo') }.to raise_error "'need_appstore_submission' value must be either `true` or `false`! Found String instead."
    end

    it 'raises an error if `milestone_duration:` parameter is passed as String' do
      expect { run_action_with(:milestone_duration, 'foo') }.to raise_error "'milestone_duration' value must be a Integer! Found String instead."
    end

    it 'raises an error if `number_of_days_from_code_freeze_to_release:` parameter is passed as String' do
      expect { run_action_with(:number_of_days_from_code_freeze_to_release, 'foo') }.to raise_error "'number_of_days_from_code_freeze_to_release' value must be a Integer! Found String instead."
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
      need_appstore_submission: false,
      github_token: test_token
    }
  end
end
