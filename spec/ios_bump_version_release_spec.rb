require 'spec_helper'

describe Fastlane::Actions::IosBumpVersionReleaseAction do
  let(:default_branch) { 'my_new_branch' }
  let(:version) { '6.30' }
  let(:next_version) { '6.31.0.0' }
  let(:next_version_short) { '6.31' }

  describe 'creates the release branch, bumps the app version and commits the changes' do
    before do
      other_action_mock = double
      allow(Fastlane::Action).to receive(:other_action).and_return(other_action_mock)
      allow(other_action_mock).to receive(:ensure_git_branch).with(branch: default_branch)
      allow(Fastlane::Helper::Ios::VersionHelper).to receive(:read_from_config_file).and_return(version)
    end

    it 'correctly uses the next version, short and long' do
      expect(Fastlane::Helper::GitHelper).to receive(:checkout_and_pull).with(default_branch)
      expect(Fastlane::Helper::GitHelper).to receive(:create_branch).with("release/#{next_version_short}", from: default_branch)

      expect(Fastlane::Helper::Ios::VersionHelper).to receive(:update_xc_configs).with(next_version, next_version_short, nil)
      expect(Fastlane::Helper::Ios::GitHelper).to receive(:commit_version_bump)

      run_described_fastlane_action(
        default_branch: default_branch
      )
    end
  end
end
