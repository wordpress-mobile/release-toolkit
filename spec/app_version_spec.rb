require 'spec_helper'

describe Fastlane::Models::AppVersion do
  describe '#initialize' do
    it 'raises an error if the major version is nil' do
      expect do
        described_class.new(nil, 2, 3, 4)
      end.to raise_error(FastlaneCore::Interface::FastlaneError), 'Major version cannot be nil'
    end

    it 'raises an error if the minor version is nil' do
      expect do
        described_class.new(1, nil, 3, 4)
      end.to raise_error(FastlaneCore::Interface::FastlaneError), 'Minor version cannot be nil'
    end

    it 'sets the major, minor, patch, and build_number' do
      app_version = described_class.new(1, 2, 3, 4)
      expect(app_version.major).to eq(1)
      expect(app_version.minor).to eq(2)
      expect(app_version.patch).to eq(3)
      expect(app_version.build_number).to eq(4)
    end
  end

  describe '#to_s' do
    it 'returns the version as a formatted string' do
      app_version = described_class.new(2, 3, 4, 5)
      expect(app_version.to_s).to eq('2.3.4.5')
    end
  end
end
