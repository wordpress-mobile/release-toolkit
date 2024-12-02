require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::DateVersionCalculator do
  describe 'calculates the next release version when using date versioning' do
    context 'when skipping to the next year' do
      it 'increments the major version number and sets the minor version to 1' do
        version = Fastlane::Models::AppVersion.new(2023, 30, 1, 2)
        bumped_version = described_class.new.next_release_version(version: version, increment_to_next_year: true)
        # Test that the original version is not modified
        expect(version.to_s).to eq('2023.30.1.2')
        expect(bumped_version.to_s).to eq('2024.1.0.0')
      end
    end

    context 'when not skipping to the next year' do
      it 'increments the minor version number' do
        version = Fastlane::Models::AppVersion.new(2023, 30, 1, 2)
        bumped_version = described_class.new.next_release_version(version: version, increment_to_next_year: false)
        # Test that the original version is not modified
        expect(version.to_s).to eq('2023.30.1.2')
        expect(bumped_version.to_s).to eq('2023.31.0.0')
      end
    end
  end
end
