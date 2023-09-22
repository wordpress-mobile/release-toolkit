require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::IncrementIntegerBuildCodeCalculator do
  describe 'calculates the next build code' do
    it 'increments the build code by 1' do
      build_code = Fastlane::Models::BuildCode.new(123)
      bumped_build_code = described_class.new.next_build_code(after: build_code)
      expect(bumped_build_code.to_s).to eq('124')
    end
  end
end
