require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/helper/version_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/app_version'

describe Fastlane::Helper::VersionHelper do
  describe 'calculates today\'s date in the correct format' do
    it 'returns a date string in the correct format' do
      allow(DateTime).to receive(:now).and_return(DateTime.new(2024, 4, 15))
      version = Fastlane::Models::AppVersion.new(19, 3, 1, 1)
      version_helper = described_class.new(version)
      expect(version_helper.today_date).to eq('20240415')
    end
  end
end
