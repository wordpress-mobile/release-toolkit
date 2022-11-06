require 'spec_helper'

RSpec.shared_examples 'github_token_initialization' do
  let(:test_token) { 'Test-GithubToken-1234' }

  describe 'GitHub Token is properly passed to the client' do
    it 'properly passes the environment variable `GITHUB_TOKEN` to Octokit::Client' do
      ENV['GITHUB_TOKEN'] = test_token
      expect(Octokit::Client).to receive(:new).with(access_token: test_token)
      run_action_without(:github_token)
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

    it 'raises an error if no `GITHUB_TOKEN` environment variable nor parameter `:github_token` is present' do
      ENV['GITHUB_TOKEN'] = nil
      expect { run_action_without(:github_token) }.to raise_error(FastlaneCore::Interface::FastlaneError, "No value found for 'github_token'")
    end
  end
end
