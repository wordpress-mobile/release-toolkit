require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::BuildCodeCalculator do
  describe 'bumps the build code' do
    it 'increments the build code by 1' do
      build_code = 735
      bumped_build_code = described_class.new.next_build_code(after: build_code)
      expect(bumped_build_code.to_s).to eq('736')
    end
  end
end
