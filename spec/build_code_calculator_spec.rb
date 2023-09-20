require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/build_code'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/versioning/calculators/build_code_calculator'

describe Fastlane::Wpmreleasetoolkit::Versioning::BuildCodeCalculator do
  describe 'bumps the build code' do
    it 'increments the build code by 1' do
      build_code = Fastlane::Models::BuildCode.new(735)
      calculator = described_class.new(build_code)
      bumped_build_code = calculator.calculate_next_build_code
      expect(bumped_build_code.to_s).to eq('736')
    end
  end
end
