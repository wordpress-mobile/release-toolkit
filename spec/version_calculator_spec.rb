require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/versioning/calculators/version_calculator'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/app_version'

describe WPMReleaseToolkit::Versioning::VersionCalculator do
  describe 'bumps the version number' do
    it 'increments the major version by 1 and sets the minor, patch, and build number to 0' do
      version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
      calculator = described_class.new(version)
      bumped_version = calculator.calculate_next_major_version.to_s
      expect(bumped_version).to eq('20.0.0.0')
    end

    it 'increments the minor version by 1 and sets the patch and build number to 0' do
      version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
      calculator = described_class.new(version)
      bumped_version = calculator.calculate_next_minor_version.to_s
      expect(bumped_version).to eq('19.4.0.0')
    end

    it 'increments the patch version by 1 and sets the build number to 0' do
      version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
      calculator = described_class.new(version)
      bumped_version = calculator.calculate_next_patch_version.to_s
      expect(bumped_version).to eq('19.3.2.0')
    end

    it 'increments the build number by 1' do
      version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
      calculator = described_class.new(version)
      bumped_version = calculator.calculate_next_build_number.to_s
      expect(bumped_version).to eq('19.3.1.2')
    end

    describe 'calculates today\'s date in the correct format' do
      it 'returns a date string in the correct format' do
        allow(DateTime).to receive(:now).and_return(DateTime.new(2024, 4, 15))
        version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
        version_calculator = described_class.new(version)
        expect(version_calculator.today_date).to eq('20240415')
      end
    end
  end
end
