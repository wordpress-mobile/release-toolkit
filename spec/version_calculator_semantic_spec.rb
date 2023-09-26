require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::SemanticVersionCalculator do
  describe 'calculates the next release version when using semantic versioning' do
    it 'increments the minor version' do
      version = Fastlane::Models::AppVersion.new(13, 5, 1, 1)
      bumped_version = described_class.new.next_release_version(after: version)
      expect(bumped_version.to_s).to eq('13.6.0.0')
    end
  end

  describe 'calculates the previous release version when using semantic versioning' do
    it 'decrements the minor version' do
      version = Fastlane::Models::AppVersion.new(13, 9, 0, 1)
      previous_version = described_class.new.previous_release_version(before: version)
      expect(previous_version.to_s).to eq('13.8.0.0')
    end
  end
end
