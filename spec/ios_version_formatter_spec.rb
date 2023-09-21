require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::IOSVersionFormatter do
  describe 'parses a version string' do
    it 'returns a version object when provided with a version string' do
      version = described_class.new.parse('1.2.3.4')
      expect(version.major).to eq(1)
      expect(version.minor).to eq(2)
      expect(version.patch).to eq(3)
      expect(version.build_number).to eq(4)
    end
  end

  describe 'formats a beta version number with the correct format' do
    it 'returns a beta version number when provided with a version object' do
      version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
      formatted_version = described_class.new.beta_version(version)
      expect(formatted_version).to eq('19.3.1.1')
    end
  end

  describe 'formats an internal version number with the correct format' do
    it 'returns an internal version number when provided with a version' do
      allow(DateTime).to receive(:now).and_return(DateTime.new(2024, 4, 15))
      version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
      formatted_version = described_class.new.internal_version(version)
      expect(formatted_version).to eq('19.3.1.20240415')
    end
  end
end
