require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::BuildCodeCalculator do
  describe 'calculates the next build code' do
    it 'increments the simple build code by 1' do
      build_code = 735
      bumped_build_code = described_class.new.next_simple_build_code(after: build_code)
      expect(bumped_build_code.to_s).to eq('736')
    end

    it 'increments the derived build code by 1 with version numbers that are single digits' do
      version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
      bumped_build_code = described_class.new.next_derived_build_code(after: version)
      expect(bumped_build_code.to_s).to eq('101020305')
    end

    it 'increments the derived build code by 1 with version numbers that are two digits' do
      version = Fastlane::Models::AppVersion.new(12, 34, 56, 78)
      bumped_build_code = described_class.new.next_derived_build_code(after: version)
      expect(bumped_build_code.to_s).to eq('112345679')
    end
  end
end
