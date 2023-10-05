require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::DateBuildCodeCalculator do
  describe 'calculates the next date build code' do
    it 'returns an AppVersion object with the build number set to today\'s date' do
      allow(DateTime).to receive(:now).and_return(DateTime.new(2024, 4, 15))
      version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
      formatted_version = described_class.new.next_build_code(version:)
      # Test that the original version is not modified
      expect(version.to_s).to eq('19.3.1.1')
      expect(formatted_version.to_s).to eq('19.3.1.20240415')
    end
  end
end
