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
      manager = described_class.new(git: repo)

      expect(manager.newest_rc_for_version(version(major: 1, minor: 1), repository: 'test', github_client: client)).to eq version(major: 1, minor: 1, rc_number: 4)
    end

    it 'ignores invalid version codes' do
      allow(client).to receive(:tags).and_return([{ name: 'fleep florp' }, { name: '1.1.rc4' }])
      manager = described_class.new(git: repo)

      expect(manager.newest_rc_for_version(version(major: 1, minor: 1), repository: 'test', github_client: client)).to eq version(major: 1, minor: 1, rc_number: 4)
    end

    it 'ignores release version codes' do
      allow(client).to receive(:tags).and_return([{ name: '10.0' }, { name: '1.1.rc4' }])
      manager = described_class.new(git: repo)

      expect(manager.newest_rc_for_version(version(major: 1, minor: 1), repository: 'test', github_client: client)).to eq version(major: 1, minor: 1, rc_number: 4)
    end

    it 'returns nil if version not found' do
      allow(client).to receive(:tags).and_return([{ name: '1.1.rc4' }, { name: '1.1.rc3' }])
      manager = described_class.new(git: repo)

      expect(manager.newest_rc_for_version(version(major: 1, minor: 2), repository: 'test', github_client: client)).to be_nil
    end

    it 'raises if GitHub response is invalid' do
      allow(client).to receive(:tags).and_return('<!-- The HTML of a GitHub Enterprise Error Page -->')
      manager = described_class.new(git: repo)
      expect { manager.newest_rc_for_version(version(major: 1, minor: 2), repository: 'test', github_client: client) }.to raise_error('Unable to connect to GitHub. Please try again later.')
    end
  end

  describe 'version calculation' do
    before do
      allow(ENV).to receive(:[]).with('BUILDKITE_PULL_REQUEST').and_return('1234')
      allow(ENV).to receive(:[]).with('CIRCLE_PR_NUMBER').and_return('1234')
      allow(ENV).to receive(:[]).with('LOCAL_PR_NUMBER').and_return('1234') # This is just here to allow local integration testing in a project
    end

    it 'provides the correct `next_rc_number` for the first RC ever' do
      allow(client).to receive(:tags).and_return([])
      manager = described_class.new(git: repo)

      version = Fastlane::Helper::Version.new(major: 1, minor: 1)
      expect(manager.next_rc_for_version(version, repository: 'test', github_client: client)).to be Fastlane::Helper::Version.new(major: 1, minor: 1, rc_number: 1)
    end

    it 'provides the correct `next_rc_number` for the first RC of a new version' do
      allow(client).to receive(:tags).and_return([{ name: '1.1.rc3' }])
      manager = described_class.new(git: repo)

      version = Fastlane::Helper::Version.new(major: 1, minor: 2)
      expect(manager.next_rc_for_version(version, repository: 'test', github_client: client)).to be Fastlane::Helper::Version.new(major: 1, minor: 2, rc_number: 1)
    end

    it 'provides the correct `next_rc_number` for the second RC of a new version' do
      allow(client).to receive(:tags).and_return([{ name: '1.2.rc1' }])
      manager = described_class.new(git: repo)

      version = Fastlane::Helper::Version.new(major: 1, minor: 2)
      expect(manager.next_rc_for_version(version, repository: 'test', github_client: client)).to be Fastlane::Helper::Version.new(major: 1, minor: 2, rc_number: 2)
    end

    it 'provides the correct `prototype_build_name` for a given branch and commit' do
      manager = described_class.new(git: repo)
      expect(manager.prototype_build_name(pr_number: 1234, commit: { sha: 'abcdef123456' })).to eq 'pr-1234-abcdef1'
    end

    it 'provides the correct `prototype_build_name` for an autodetected PR and commit' do
      allow(repo).to receive(:log).and_return([{ sha: 'abcdef123456' }])
      manager = described_class.new(git: repo)
      expect(manager.prototype_build_name).to eq 'pr-1234-abcdef1'
    end

    it 'provides the correct `prototype_build_number` for a given commit' do
      allow(repo).to receive(:log).and_return([{ date: now }])
      manager = described_class.new(git: repo)
      expect(manager.prototype_build_number).to eq now.to_i
    end

    it 'provides the correct `alpha_build_name` for a given branch and commit' do
      allow(repo).to receive(:current_branch).and_return('foo')
      allow(repo).to receive(:log).and_return([{ sha: 'abcdef123456' }])
      manager = described_class.new(git: repo)
      expect(manager.alpha_build_name).to eq 'foo-abcdef1'
    end

    it 'provides the correct `alpha_build_number` (ie – the current unix timestamp)' do
      manager = described_class.new(git: repo)
      expect(manager.alpha_build_number(now: now)).to eq now.to_i
    end
  end
end
