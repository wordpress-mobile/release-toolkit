require 'spec_helper'

describe Fastlane::Actions::CreateNewMilestoneAction do
  describe 'initialize' do
    let(:test_token) { 'Test-GithubToken-1234' }
    let(:test_milestone) { { title: '10.1', due_on: '2022-10-31T07:00:00Z' } }
    let(:mock_params) do
      {
        repository: 'test-repository',
        need_appstore_submission: false
      }
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
      ENV['GITHUB_TOKEN'] = nil
      mock_params[:github_token] = nil
      allow(Octokit::Client).to receive(:new).and_return(client)
    end

    context 'with github_token' do
      it 'properly passes the environment variable `GITHUB_TOKEN` all the way to Octokit::Client' do
        ENV['GITHUB_TOKEN'] = test_token
        expect(Octokit::Client).to receive(:new).with(access_token: test_token)
        run_described_fastlane_action(mock_params)
      end

      it 'properly passes the parameter `:github_token` all the way to Octokit::Client' do
        mock_params[:github_token] = test_token
        expect(Octokit::Client).to receive(:new).with(access_token: test_token)
        run_described_fastlane_action(mock_params)
      end

      it 'prioritizes `:github_token` parameter over `GITHUB_TOKEN` enviroment variable if both are present' do
        ENV['GITHUB_TOKEN'] = 'Test-EnvGithubToken-1234'
        mock_params[:github_token] = test_token
        expect(Octokit::Client).to receive(:new).with(access_token: test_token)
        run_described_fastlane_action(mock_params)
      end

      it 'prints an error if no `GITHUB_TOKEN` environment variable nor parameter `:github_token` is present' do
        expect { run_described_fastlane_action(mock_params) }.to raise_error(FastlaneCore::Interface::FastlaneError)
      end
    end

    context 'with default parameters' do
      let(:glithub_helper) do
        instance_double(
          Fastlane::Helper::GithubHelper,
          get_last_milestone: test_milestone,
          create_milestone: nil
        )
      end

      before do
        mock_params[:github_token] = test_token
        allow(Fastlane::Helper::GithubHelper).to receive(:new).and_return(glithub_helper)
      end

      it 'uses default value when neither `GHHELPER_NUMBER_OF_DAYS_FROM_CODE_FREEZE_TO_RELEASE` environment variable nor parameter `:number_of_days_from_code_freeze_to_release` is present' do
        default_code_freeze_days = 14
        mock_params[:number_of_days_from_code_freeze_to_release] = nil
        ENV['GHHELPER_NUMBER_OF_DAYS_FROM_CODE_FREEZE_TO_RELEASE'] = nil
        expect(glithub_helper).to receive(:create_milestone).with(
          anything,
          anything,
          anything,
          anything,
          default_code_freeze_days,
          anything
        )
        run_described_fastlane_action(mock_params)
      end

      it 'uses default value when neither `GHHELPER_MILESTONE_DURATION` environment variable nor parameter `:milestone_duration` is present' do
        default_milestone_duration = 14
        mock_params[:milestone_duration] = nil
        ENV['GHHELPER_MILESTONE_DURATION'] = nil
        expect(glithub_helper).to receive(:create_milestone).with(
          anything,
          anything,
          anything,
          default_milestone_duration,
          anything,
          anything
        )
        run_described_fastlane_action(mock_params)
      end
    end
  end

  describe 'get_last_milestone' do
    let(:test_repository) { 'test-repository' }
    let(:test_milestone) { { title: '10.1', due_on: '2022-10-31T07:00:00Z' } }
    let(:mock_params) do
      {
        repository: test_repository,
        need_appstore_submission: false,
        github_token: 'Test-GithubToken-1234'
      }
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

    it 'properly passes the repository all the way down to the Octokit::Client to list the existing milestones' do
      allow(Octokit::Client).to receive(:new).and_return(client)
      expect(client).to receive(:list_milestones).with(test_repository, { state: 'open' })
      run_described_fastlane_action(mock_params)
    end
  end

  describe 'create_milestone' do
    let(:test_repository) { 'test-repository' }
    let(:test_milestone_number) { '10.2' }
    let(:test_milestone) { { title: '10.1', due_on: '2022-10-31T07:00:00Z' } }
    let(:mock_params) do
      {
        repository: test_repository,
        need_appstore_submission: false,
        github_token: 'Test-GithubToken-1234'
      }
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

    it 'properly passes the parameters all the way down to the Octokit::Client' do
      comment = "Code freeze: November 14, 2022\nApp Store submission: November 28, 2022\nRelease: November 28, 2022\n"
      options = { due_on: '2022-11-14T12:00:00Z', description: comment }
      allow(Octokit::Client).to receive(:new).and_return(client)
      expect(client).to receive(:create_milestone).with(test_repository, test_milestone_number, options)
      run_described_fastlane_action(mock_params)
    end
  end
end
