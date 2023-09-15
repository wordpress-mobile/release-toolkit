require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/app_version'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/formatters/ios_version_formatter'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/formatters/version_formatter'

describe Fastlane::Formatters::IosVersionFormatter do
  describe 'formats a beta version number with the correct format' do
    it 'returns a beta version number when provided with a version object' do
      version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
      formatter = described_class.new(version)
      formatted_version = formatter.beta_version
      expect(formatted_version.to_s).to eq('19.3.1.1')
    end
  end

  describe 'formats an internal version number with the correct format' do
    it 'returns an internal version number when provided with a version' do
      allow(DateTime).to receive(:now).and_return(DateTime.new(2024, 4, 15))
      version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
      formatter = described_class.new(version)
      formatted_version = formatter.internal_version
      expect(formatted_version.to_s).to eq('19.3.1.20240415')
    end
  end
end
