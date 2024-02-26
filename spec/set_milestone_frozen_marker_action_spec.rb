require 'spec_helper'
require 'tmpdir'

describe Fastlane::Actions::SetMilestoneFrozenMarkerAction do
  let(:repo) { 'automattic/demorepo' }
  let(:github_token) { 'stubbed-gh-token' }
  let(:client) do
    instance_double(
      Octokit::Client,
      user: instance_double('User', name: 'test'),
      'auto_paginate=': nil
    )
  end
  let(:test_milestones) do
    [
      { title: '9.8 Some Custom Title', number: 980 },
      { title: '10.0 The Big Update ❄️', number: 1000 },
    ]
  end

  before do
    allow(Octokit::Client).to receive(:new).and_return(client)
  end

  context 'when passing `freeze: false` (default)' do
    it 'adds the frozen marker if not present already' do
      allow(client).to receive(:list_milestones).with(repo).and_return(test_milestones)
      expect(client).to receive(:update_milestone).with(repo, 980, { title: '9.8 Some Custom Title ❄️' })

      run_described_fastlane_action(
        repository: repo,
        milestone: '9.8',
        freeze: true,
        github_token: github_token
      )
    end

    it 'does not add the frozen marker if already present' do
      allow(client).to receive(:list_milestones).with(repo).and_return(test_milestones)
      expect(client).not_to receive(:update_milestone)
      expect(Fastlane::UI).to receive(:message).with('Logged in as: test')
      expect(Fastlane::UI).to receive(:message).with('Milestone `10.0 The Big Update ❄️` is already frozen. Nothing to do')

      run_described_fastlane_action(
        repository: repo,
        milestone: '10.0',
        freeze: true,
        github_token: github_token
      )
    end
  end

  context 'when passing `freeze: false`' do
    it 'removes the frozen marker if present' do
      allow(client).to receive(:list_milestones).with(repo).and_return(test_milestones)
      expect(client).to receive(:update_milestone).with(repo, 1000, { title: '10.0 The Big Update' })

      run_described_fastlane_action(
        repository: repo,
        milestone: '10.0',
        freeze: false,
        github_token: github_token
      )
    end

    it 'does nothing when trying to remove the marker while not present' do
      allow(client).to receive(:list_milestones).with(repo).and_return(test_milestones)
      expect(client).not_to receive(:update_milestone)
      expect(Fastlane::UI).to receive(:message).with('Logged in as: test')
      expect(Fastlane::UI).to receive(:message).with('Milestone `9.8 Some Custom Title` is not frozen. Nothing to do')

      run_described_fastlane_action(
        repository: repo,
        milestone: '9.8',
        freeze: false,
        github_token: github_token
      )
    end
  end
end
