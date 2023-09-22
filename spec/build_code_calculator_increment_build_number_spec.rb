require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::IncrementBuildNumberBuildCodeCalculator do
  describe 'calculates the next build code' do
    it 'increments the build code by 1' do
      version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
      bumped_build_code = described_class.new.next_build_code(after: version)
      expect(bumped_build_code.to_s).to eq('5')
    end
  end
end
