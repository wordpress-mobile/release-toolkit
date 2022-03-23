require 'spec_helper'

describe Fastlane::Helper::VersionHelper do
  let(:client) do
    instance_double(Octokit::Client)
  end

  let(:repo) do
    instance_double(Git::Base)
  end

  let(:now) do
    DateTime.now
  end

  describe 'version lookup' do
    it 'returns the newest RC version' do
      allow(client).to receive(:tags).and_return([{ name: '1.1.rc4' }, { name: '1.1.rc3' }])
      manager = described_class.new(github_client: client, git: repo)

      expect(manager.newest_rc_for_version(version(major: 1, minor: 1), repository: 'test')).to eq version(major: 1, minor: 1, rc_number: 4)
    end

    it 'ignores invalid version codes' do
      allow(client).to receive(:tags).and_return([{ name: 'fleep florp' }, { name: '1.1.rc4' }])
      manager = described_class.new(github_client: client, git: repo)

      expect(manager.newest_rc_for_version(version(major: 1, minor: 1), repository: 'test')).to eq version(major: 1, minor: 1, rc_number: 4)
    end

    it 'returns nil if version not found' do
      allow(client).to receive(:tags).and_return([{ name: '1.1.rc4' }, { name: '1.1.rc3' }])
      manager = described_class.new(github_client: client, git: repo)

      expect(manager.newest_rc_for_version(version(major: 1, minor: 2), repository: 'test')).to be_nil
    end
  end

  describe 'version calculation' do
    it 'provides the correct `next_rc_number` for the first RC ever' do
      allow(client).to receive(:tags).and_return([])
      manager = described_class.new(github_client: client, git: repo)

      version = Fastlane::Helper::Version.new(major: 1, minor: 1)
      expect(manager.next_rc_for_version(version, repository: 'test')).to be Fastlane::Helper::Version.new(major: 1, minor: 1, rc_number: 1)
    end

    it 'provides the correct `next_rc_number` for the first RC of a new version' do
      allow(client).to receive(:tags).and_return([{ name: '1.1.rc3' }])
      manager = described_class.new(github_client: client, git: repo)

      version = Fastlane::Helper::Version.new(major: 1, minor: 2)
      expect(manager.next_rc_for_version(version, repository: 'test')).to be Fastlane::Helper::Version.new(major: 1, minor: 2, rc_number: 1)
    end

    it 'provides the correct `next_rc_number` for the second RC of a new version' do
      allow(client).to receive(:tags).and_return([{ name: '1.2.rc1' }])
      manager = described_class.new(github_client: client, git: repo)

      version = Fastlane::Helper::Version.new(major: 1, minor: 2)
      expect(manager.next_rc_for_version(version, repository: 'test')).to be Fastlane::Helper::Version.new(major: 1, minor: 2, rc_number: 2)
    end

    it 'provides the correct `prototype_build_name` for a given branch and commit' do
      allow(repo).to receive(:current_branch).and_return('foo')
      allow(repo).to receive(:log).and_return([{ sha: 'abcdef123456' }])
      manager = described_class.new(github_client: client, git: repo)
      expect(manager.prototype_build_name).to eq 'foo-abcdef1'
    end

    it 'provides the correct `prototype_build_number` for a given commit' do
      allow(repo).to receive(:log).and_return([{ date: now }])
      manager = described_class.new(github_client: client, git: repo)
      expect(manager.prototype_build_number).to eq now.to_i
    end

    it 'provides the correct `alpha_build_name` for a given branch and commit' do
      allow(repo).to receive(:current_branch).and_return('foo')
      allow(repo).to receive(:log).and_return([{ sha: 'abcdef123456' }])
      manager = described_class.new(github_client: client, git: repo)
      expect(manager.alpha_build_name).to eq 'foo-abcdef1'
    end

    it 'provides the correct `alpha_build_number` (ie – the current unix timestamp)' do
      manager = described_class.new(github_client: client, git: repo)
      expect(manager.alpha_build_number(now: now)).to eq now.to_i
    end
  end
end