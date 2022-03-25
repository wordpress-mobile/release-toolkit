require 'spec_helper'

def mock_version(major: 1, minor: 2, patch: 3, rc_number: 1)
  Fastlane::Helper::Version.new(
    major: major,
    minor: minor,
    patch: patch,
    rc_number: rc_number
  )
end

def version(major:, minor:, patch: 0, rc_number: nil)
  Fastlane::Helper::Version.new(
    major: major,
    minor: minor,
    patch: patch,
    rc_number: rc_number
  )
end

describe Fastlane::Helper::Version do
  describe 'helpers' do
    it 'correctly extracts ints' do
      expect(Fastlane::Helper::VersionHelpers.extract_ints_from_string('beta1')).to eq ['1']
      expect(Fastlane::Helper::VersionHelpers.extract_ints_from_string('b1')).to eq ['1']
      expect(Fastlane::Helper::VersionHelpers.extract_ints_from_string('rc1')).to eq ['1']
      expect(Fastlane::Helper::VersionHelpers.extract_ints_from_string('rc-1')).to eq ['1']
      expect(Fastlane::Helper::VersionHelpers.extract_ints_from_string('52rc-1')).to eq %w[52 1]
      expect(Fastlane::Helper::VersionHelpers.extract_ints_from_string('1a2b3')).to eq %w[1 2 3]
    end

    it 'corrently parses rc strings' do
      expect(Fastlane::Helper::VersionHelpers.rc_segments_from_string('rc1')).to eq ['1']
      expect(Fastlane::Helper::VersionHelpers.rc_segments_from_string('1rc2')).to eq %w[1 2]
    end

    it 'corrently identifies valid integer strings' do
      expect(Fastlane::Helper::VersionHelpers.string_is_valid_int('1')).to eq true
      expect(Fastlane::Helper::VersionHelpers.string_is_valid_int('01')).to eq true
    end

    it 'correctly combines components and rc segments' do
      expect(Fastlane::Helper::VersionHelpers.combine_components_and_rc_segments(['1'], %w[2 3])).to eq %w[1 2 0 3]
      expect(Fastlane::Helper::VersionHelpers.combine_components_and_rc_segments(%w[1 2], ['3'])).to eq %w[1 2 0 3]
      expect(Fastlane::Helper::VersionHelpers.combine_components_and_rc_segments(%w[1 2], %w[3 4])).to eq %w[1 2 3 4]
      expect(Fastlane::Helper::VersionHelpers.combine_components_and_rc_segments(%w[1 2 3], %w[4])).to eq %w[1 2 3 4]
    end

    it 'raises for invalid component and rc segment combinations' do
      expect { Fastlane::Helper::VersionHelpers.combine_components_and_rc_segments(%w[1 2 3], %w[1 32]) }.to raise_error 'Invalid components: ["1", "2", "3"] or rc_segments: ["1", "32"]'
    end
  end

  describe 'compare' do
    it 'correctly recognizes that different versions are equal' do
      expect(version(major: 1, minor: 2, patch: 3, rc_number: 4)).to eq version(major: 1, minor: 2, patch: 3, rc_number: 4)
      expect(version(major: 1, minor: 2, patch: 3, rc_number: 4)).to be version(major: 1, minor: 2, patch: 3, rc_number: 4)
    end

    it 'correctly recognizes that one version is an RC of another version' do
      expect(version(major: 1, minor: 2, rc_number: 1).is_rc_of(version(major: 1, minor: 2))).to be true
      expect(version(major: 1, minor: 2).is_rc_of(version(major: 1, minor: 2, rc_number: 1))).to be false
      expect(version(major: 1, minor: 2).is_rc_of(version(major: 1, minor: 2))).to be false
    end

    it 'correctly recognizes that two different versions are the same except for their RC' do
      expect(version(major: 1, minor: 2, rc_number: 1).is_different_rc_of(version(major: 1, minor: 2, rc_number: 2))).to be true
      expect(version(major: 1, minor: 2).is_different_rc_of(version(major: 1, minor: 2, rc_number: 3))).to be false
      expect(version(major: 1, minor: 2, rc_number: 1).is_different_rc_of(version(major: 1, minor: 2))).to be false
    end

    it 'correctly recognizes that two different versions are the same except for their PATCH segment' do
      expect(version(major: 1, minor: 2).is_different_patch_of(version(major: 1, minor: 2, patch: 1))).to be true
    end

    it 'correctly sorts production versions' do
      expect(version(major: 1, minor: 2)).to be < version(major: 1, minor: 3)
      expect(version(major: 1, minor: 2)).to be < version(major: 1, minor: 2, patch: 1)
      expect(version(major: 1, minor: 2, patch: 1)).to be < version(major: 1, minor: 2, patch: 2)
    end

    it 'correctly sorts pre-release versions' do
      expect(version(major: 1, minor: 2, rc_number: 1)).to be < version(major: 1, minor: 2, rc_number: 2)
      expect(version(major: 1, minor: 2, rc_number: 1)).to be == version(major: 1, minor: 2, rc_number: 1)
    end

    it 'correctly sorts pre-release versions against release versions' do
      expect(version(major: 1, minor: 1)).to be < version(major: 1, minor: 2, rc_number: 1)
    end

    it 'correctly identifies release versions as newer than RC versions' do
      # Test these both ways to validate the custom sorting logic
      expect(version(major: 1, minor: 2, rc_number: 1)).to be < version(major: 1, minor: 2)
      expect(version(major: 1, minor: 2)).to be > version(major: 1, minor: 2, rc_number: 1)
    end
  end

  describe 'create' do
    it 'correctly parses two-segment version numbers' do
      expect(described_class.create('1.0')).to eq version(major: 1, minor: 0)
      expect(described_class.create('1.2')).to eq version(major: 1, minor: 2)
      expect(described_class.create('1.00')).to eq version(major: 1, minor: 0)
    end

    it 'correctly parses three-segment version numbers' do
      expect(described_class.create('01.2.3')).to eq version(major: 1, minor: 2, patch: 3)
    end

    it 'correctly parses four-segment version numbers' do
      expect(described_class.create('01.2.3.4')).to eq version(major: 1, minor: 2, patch: 3, rc_number: 4)
    end

    it 'correctly parses two-segment dotted release candidates' do
      expect(described_class.create('1.2.rc1')).to eq version(major: 1, minor: 2, rc_number: 1)
    end

    it 'correctly parses two-segment concatenated release candidates' do
      expect(described_class.create('1.2rc1')).to eq version(major: 1, minor: 2, patch: 0, rc_number: 1)
    end

    it 'correctly parses two-segment dashed release candidates' do
      expect(described_class.create('1.2-rc-1')).to eq version(major: 1, minor: 2, patch: 0, rc_number: 1)
      expect(described_class.create('1.2-RC-1')).to eq version(major: 1, minor: 2, patch: 0, rc_number: 1)
    end

    it 'correctly parses three-segment dotted release candidates' do
      expect(described_class.create('1.2.3.rc.1')).to eq version(major: 1, minor: 2, patch: 3, rc_number: 1)
      expect(described_class.create('1.2.3.RC.1')).to eq version(major: 1, minor: 2, patch: 3, rc_number: 1)
    end

    it 'correctly parses three-segment dashed release candidates' do
      expect(described_class.create('1.2.3-rc-1')).to eq version(major: 1, minor: 2, patch: 3, rc_number: 1)
      expect(described_class.create('1.2.3-RC-1')).to eq version(major: 1, minor: 2, patch: 3, rc_number: 1)
    end

    it 'correctly parses three-segment concatenated release candidates' do
      expect(described_class.create('1.2.3rc1')).to eq version(major: 1, minor: 2, patch: 3, rc_number: 1)
      expect(described_class.create('1.2.3RC1')).to eq version(major: 1, minor: 2, patch: 3, rc_number: 1)
    end

    # Github encourages version numbers prefixed with `v`
    it 'correctly parses v-prefixed version numbers' do
      expect(described_class.create('v23.8.0.00')).to eq version(major: 23, minor: 8, patch: 0, rc_number: 0)
      expect(described_class.create('V23.8.0.00')).to eq version(major: 23, minor: 8, patch: 0, rc_number: 0)
    end

    it 'rejects invalid version formats' do
      expect(described_class.create('alpha/2022-03-16/1647467717')).to be_nil
      expect(described_class.create('builds/beta/239008')).to be_nil
      expect(described_class.create('alpha-abcdef')).to be_nil
      expect(described_class.create('alpha-123456')).to be_nil
      expect(described_class.create('1.2.3.4.5')).to be_nil
    end

    it 'raises for invalid version codes if requested' do
      expect { described_class.create!('1.2.3.4.5') }.to raise_error 'Invalid Version: 1.2.3.4.5'
    end

    it 'does not raise for valid version codes' do
      expect(described_class.create!('1.2.3.4')).to eq version(major: 1, minor: 2, patch: 3, rc_number: 4)
    end
  end

  describe 'properties' do
    it 'patch? is valid' do
      expect(described_class.create('1.2').patch?).to be false
      expect(described_class.create('1.2.1').patch?).to be true
    end

    it 'prerelease? is valid' do
      expect(described_class.create('1.2').prerelease?).to be false
      expect(described_class.create('1.2rc1').prerelease?).to be true
    end
  end

  describe 'formatters' do
    it 'prints the Android version name correctly' do
      expect(described_class.new(major: 1, minor: 2).android_version_name).to eq '1.2'
      expect(described_class.new(major: 1, minor: 2, patch: 0).android_version_name).to eq '1.2'
      expect(described_class.new(major: 1, minor: 2, patch: 3).android_version_name).to eq '1.2.3'
      expect(described_class.new(major: 1, minor: 2, patch: 3, rc_number: 4).android_version_name).to eq '1.2.3-rc-4'
      expect(described_class.new(major: 1, minor: 2, patch: 0, rc_number: 4).android_version_name).to eq '1.2-rc-4'
    end

    it 'prints the Android version code correctly' do
      expect(described_class.new(major: 1, minor: 2).android_version_code).to eq '11020000'
      expect(described_class.new(major: 1, minor: 2, patch: 3).android_version_code).to eq '11020300'
      expect(described_class.new(major: 1, minor: 2, patch: 3, rc_number: 4).android_version_code).to eq '11020304'
      expect(described_class.new(major: 1, minor: 2, patch: 0, rc_number: 4).android_version_code).to eq '11020004'
    end

    it 'prints the Android version code correctly if a prefix is provided' do
      expect(described_class.new(major: 1, minor: 2).android_version_code(prefix: 2)).to eq '21020000'
      expect(described_class.new(major: 1, minor: 2, patch: 3).android_version_code(prefix: 2)).to eq '21020300'
      expect(described_class.new(major: 1, minor: 2, patch: 3, rc_number: 4).android_version_code(prefix: 2)).to eq '21020304'
      expect(described_class.new(major: 1, minor: 2, patch: 0, rc_number: 4).android_version_code(prefix: 2)).to eq '21020004'
    end

    it 'prints the iOS version code correctly' do
      expect(described_class.new(major: 1, minor: 2).ios_version_number).to eq '1.2.0.0'
      expect(described_class.new(major: 1, minor: 2, patch: 0).ios_version_number).to eq '1.2.0.0'
      expect(described_class.new(major: 1, minor: 2, patch: 3).ios_version_number).to eq '1.2.3.0'
      expect(described_class.new(major: 1, minor: 2, patch: 3, rc_number: 4).ios_version_number).to eq '1.2.3.4'
      expect(described_class.new(major: 1, minor: 2, patch: 0, rc_number: 4).ios_version_number).to eq '1.2.0.4'
    end
  end

  describe 'bumpers' do
    it 'bumps the major version correctly' do
      new_version = described_class.new(major: 1, minor: 5).next_major_version
      expect(new_version).to eq described_class.new(major: 2, minor: 0)
    end

    it 'bumps the minor version correctly' do
      new_version = described_class.new(major: 1, minor: 0).next_minor_version
      expect(new_version).to eq described_class.new(major: 1, minor: 1)
    end

    it 'rolls the major version as needed when bumping the minor version' do
      new_version = described_class.new(major: 1, minor: 9).next_minor_version
      expect(new_version).to eq described_class.new(major: 2, minor: 0)
    end

    it 'bumps the patch version correctly' do
      new_version = described_class.new(major: 1, minor: 0).next_patch_version
      expect(new_version).to eq described_class.new(major: 1, minor: 0, patch: 1)
    end

    it 'bumps the rc version correctly when none is present' do
      new_version = described_class.new(major: 1, minor: 0).next_rc_version
      expect(new_version).to eq described_class.new(major: 1, minor: 0, rc_number: 1)
    end

    it 'bumps the rc version correctly for an existing RC' do
      new_version = described_class.new(major: 1, minor: 0, rc_number: 1).next_rc_version
      expect(new_version).to eq described_class.new(major: 1, minor: 0, rc_number: 2)
    end
  end
end
