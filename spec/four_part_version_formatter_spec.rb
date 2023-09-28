require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::FourPartVersionFormatter do
  describe 'parses a version string' do
    it 'returns a version object when provided with a version string' do
      version = described_class.new.parse('1.2.3.4')
      expect(version.major).to eq(1)
      expect(version.minor).to eq(2)
      expect(version.patch).to eq(3)
      expect(version.build_number).to eq(4)
    end
  end
end
