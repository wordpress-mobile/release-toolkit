require 'spec_helper'

describe Fastlane::Actions::SetfrozentagAction do
  describe 'initialize' do
    let(:test_token) { 'Test-GithubToken-1234' }
    let(:test_milestone) { { title: '10.1', number: 1234 } }
    let(:mock_params) do
      {
        repository: 'test-repository',
        milestone: test_milestone[:title]
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
          get_milestone: test_milestone,
          create_milestone: nil
        )
      end

      before do
        mock_params[:github_token] = test_token
        allow(Fastlane::Helper::GithubHelper).to receive(:new).and_return(glithub_helper)
      end

      it 'froze the milestone when the parameter `:freeze` is not present' do
        default_freeze_milestone = { title: '10.1 ❄️' }
        expect(glithub_helper).to receive(:update_milestone).with(
          repository: anything,
          number: anything,
          options: default_freeze_milestone
        )
        run_described_fastlane_action(mock_params)
      end
    end
  end

  describe 'get_milestone' do
    let(:test_repository) { 'test-repository' }
    let(:test_milestone) { { title: '10.1', number: 1234 } }
    let(:mock_params) do
      {
        repository: test_repository,
        milestone: test_milestone[:title],
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

    it 'properly passes parameters all the way down to the Octokit::Client' do
      expect(client).to receive(:list_milestones).with(test_repository)
      run_described_fastlane_action(mock_params)
    end
  end

  describe 'update_milestone' do
    let(:test_repository) { 'test-repository' }
    let(:test_milestone) { { title: '10.1', number: 1234 } }
    let(:mock_params) do
      {
        repository: test_repository,
        milestone: test_milestone[:title],
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

    it 'properly passes parameters all the way down to the Octokit::Client' do
      allow(Octokit::Client).to receive(:new).and_return(client)
      expect(client).to receive(:update_milestone).with(test_repository, test_milestone[:number], { title: '10.1 ❄️' })
      run_described_fastlane_action(mock_params)
    end
  end
end
