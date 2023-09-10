require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/bumpers/version_bumper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/app_version'

describe Fastlane::Bumpers::VersionBumper do
  describe 'bumps the version number' do
    it 'increments the major version by 1 and sets the minor, patch, and build number to 0' do
      version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
      bumper = described_class.new(version)
      bumped_version = bumper.bump_major_version.to_s
      expect(bumped_version).to eq('20.0.0.0')
    end

    it 'increments the minor version by 1 and sets the patch and build number to 0' do
      version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
      bumper = described_class.new(version)
      bumped_version = bumper.bump_minor_version.to_s
      expect(bumped_version).to eq('19.4.0.0')
    end

    it 'increments the patch version by 1 and sets the build number to 0' do
      version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
      bumper = described_class.new(version)
      bumped_version = bumper.bump_patch_version.to_s
      expect(bumped_version).to eq('19.3.2.0')
    end

    it 'increments the build number by 1' do
      version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
      bumper = described_class.new(version)
      bumped_version = bumper.bump_build_number.to_s
      expect(bumped_version).to eq('19.3.1.2')
    end
  end
end
