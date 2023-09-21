require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::VersionCalculator do
  describe 'calculates the next version number' do
    it 'increments the major version by 1 and sets the minor, patch, and build number to 0' do
      version = Fastlane::Models::AppVersion.new('19.3.1.1')
      bumped_version = described_class.new.next_major_version(after: version)
      expect(bumped_version.to_s).to eq('20.0.0.0')
    end

    it 'increments the minor version by 1 and sets the patch and build number to 0' do
      version = Fastlane::Models::AppVersion.new('19.3.1.1')
      bumped_version = described_class.new.next_minor_version(after: version)
      expect(bumped_version.to_s).to eq('19.4.0.0')
    end

    it 'increments the patch version by 1 and sets the build number to 0' do
      version = Fastlane::Models::AppVersion.new('19.3.1.1')
      bumped_version = described_class.new.next_patch_version(after: version)
      expect(bumped_version.to_s).to eq('19.3.2.0')
    end

    it 'increments the build number by 1' do
      version = Fastlane::Models::AppVersion.new('19.3.1.1')
      bumped_version = described_class.new.next_build_number(after: version)
      expect(bumped_version.to_s).to eq('19.3.1.2')
    end

    describe 'calculates today\'s date in the correct format' do
      it 'returns a date string in the correct format' do
        allow(DateTime).to receive(:now).and_return(DateTime.new(2024, 4, 15))
        today_date = described_class.new.today_date
        expect(today_date).to eq('20240415')
      end
    end
  end

  describe 'calculates the previous version number' do
    it 'decrements the major version by 1 and sets the minor, patch, and build number to 0' do
      version = Fastlane::Models::AppVersion.new('13.2.1.3')
      previous_version = described_class.new.previous_major_version(before: version)
      expect(previous_version.to_s).to eq('12.0.0.0')
    end

    it 'decrements the minor version by 1 and sets the patch and build number to 0' do
      version = Fastlane::Models::AppVersion.new('13.2.1.3')
      previous_version = described_class.new.previous_minor_version(before: version)
      expect(previous_version.to_s).to eq('13.1.0.0')
    end

    it 'decrements the patch version by 1 and sets the build number to 0' do
      version = Fastlane::Models::AppVersion.new('13.2.1.3')
      previous_version = described_class.new.previous_patch_version(before: version)
      expect(previous_version.to_s).to eq('13.2.0.0')
    end

    it 'decrements the build number by 1' do
      version = Fastlane::Models::AppVersion.new('13.2.1.3')
      previous_version = described_class.new.previous_build_number(before: version)
      expect(previous_version.to_s).to eq('13.2.1.2')
    end
  end
end
