require 'spec_helper'

describe Fastlane::Models::AppVersion do
  describe '#initialize' do
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

    it 'handles nil values' do
      app_version = described_class.new(nil, nil, nil, nil)
      # The AppVersion class uses `to_i` on the values, so nil values are converted to 0
      expect(app_version.to_s).to eq('0.0.0.0')
    end
  end
end
