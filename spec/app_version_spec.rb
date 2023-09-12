require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/app_version'

describe Fastlane::Models::AppVersion do
  describe '#initialize' do
    it 'should set the major, minor, patch, and build_number' do
      app_version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
      expect(app_version.major).to eq(1)
      expect(app_version.minor).to eq(2)
      expect(app_version.patch).to eq(3)
      expect(app_version.build_number).to eq(4)
    end
  end

  describe '#to_s' do
    it 'should return the version as a formatted string' do
      app_version = Fastlane::Models::AppVersion.new(2, 3, 4, 5)
      expect(app_version.to_s).to eq('2.3.4.5')
    end

    it 'should handle nil values' do
      app_version = Fastlane::Models::AppVersion.new(nil, nil, nil, nil)
      expect(app_version.to_s).to eq('...')
    end
  end
end
