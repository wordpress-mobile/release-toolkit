require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::AbstractVersionCalculator do
  describe 'calculates the next version number' do
    it 'increments the major version by 1 and sets the minor, patch, and build number to 0' do
      version = Fastlane::Models::AppVersion.new(19, 20, 21, 22)
      bumped_version = described_class.new.next_major_version(version: version)

      # Test that the original version is not modified
      expect(version.to_s).to eq('19.20.21.22')
      expect(bumped_version.to_s).to eq('20.0.0.0')
    end

    it 'increments the minor version by 1 and sets the patch and build number to 0' do
      version = Fastlane::Models::AppVersion.new(19, 20, 21, 22)
      bumped_version = described_class.new.next_minor_version(version: version)

      # Test that the original version is not modified
      expect(version.to_s).to eq('19.20.21.22')
      expect(bumped_version.to_s).to eq('19.21.0.0')
    end

    it 'increments the patch version by 1 and sets the build number to 0' do
      version = Fastlane::Models::AppVersion.new(19, 20, 21, 22)
      bumped_version = described_class.new.next_patch_version(version: version)

      # Test that the original version is not modified
      expect(version.to_s).to eq('19.20.21.22')
      expect(bumped_version.to_s).to eq('19.20.22.0')
    end

    it 'increments the build number by 1' do
      version = Fastlane::Models::AppVersion.new(19, 20, 21, 22)
      bumped_version = described_class.new.next_build_number(version: version)

      # Test that the original version is not modified
      expect(version.to_s).to eq('19.20.21.22')
      expect(bumped_version.to_s).to eq('19.20.21.23')
    end
  end

  describe 'calculates the previous version number' do
    it 'decrements the patch version by 1 and sets the build number to 0' do
      version = Fastlane::Models::AppVersion.new(13, 2, 1, 3)
      previous_version = described_class.new.previous_patch_version(version: version)

      # Test that the original version is not modified
      expect(version.to_s).to eq('13.2.1.3')
      expect(previous_version.to_s).to eq('13.2.0.0')
    end
  end

  describe 'calculates whether a release is a hotfix' do
    it 'calculates that a hotfix release version is a hotfix' do
      version = Fastlane::Models::AppVersion.new(1, 0, 3, 0)
      hotfix = described_class.new.release_is_hotfix?(version: version)

      expect(hotfix).to be true
    end

    it 'calculates that a non-hotfix release version is not a hotfix' do
      version = Fastlane::Models::AppVersion.new(1, 2, 0, 4)
      hotfix = described_class.new.release_is_hotfix?(version: version)

      expect(hotfix).to be false
    end
  end
end
