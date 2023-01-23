require 'spec_helper'

describe Fastlane::Actions::IosBumpVersionReleaseAction do
  let(:default_branch) { 'my_new_branch' }
  let(:ensure_git_action_instance) { double() }
  let(:versions) { ['6.30'] }
  let(:next_version) { '6.31.0.0' }
  let(:next_version_short) { '6.31' }

  describe 'creates the release branch, bumps the app version and commits the changes' do
    before do
      allow(Fastlane::Action).to receive(:other_action).and_return(ensure_git_action_instance)
      allow(ensure_git_action_instance).to receive(:ensure_git_branch).with(branch: default_branch)

      allow(Fastlane::Helper::GitHelper).to receive(:checkout_and_pull).with(default_branch)
      allow(Fastlane::Helper::GitHelper).to receive(:create_branch).with("release/#{next_version_short}", from: default_branch)

      allow(Fastlane::Helper::Ios::VersionHelper).to receive(:get_version_strings).and_return(versions)
      allow(Fastlane::Helper::Ios::VersionHelper).to receive(:update_xc_configs).with(next_version, next_version_short, nil)
    end

    it 'does the fastlane deliver update' do
      skip_deliver = false

      expect(Fastlane::Helper::Ios::VersionHelper).to receive(:update_fastlane_deliver).with(next_version_short)
      expect(Fastlane::Helper::Ios::GitHelper).to receive(:commit_version_bump).with(include_deliverfile: !skip_deliver, include_metadata: false)

      run_described_fastlane_action(
        skip_deliver: skip_deliver,
        default_branch: default_branch
      )
    end

    it 'skips the fastlane deliver update properly' do
      skip_deliver = true

      expect(Fastlane::Helper::Ios::VersionHelper).not_to receive(:update_fastlane_deliver)
      expect(Fastlane::Helper::Ios::GitHelper).to receive(:commit_version_bump).with(include_deliverfile: !skip_deliver, include_metadata: false)

      run_described_fastlane_action(
        skip_deliver: skip_deliver,
        default_branch: default_branch
      )
    end
  end
end
