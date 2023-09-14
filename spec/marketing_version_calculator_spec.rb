require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/calculators/marketing_version_calculator'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/calculators/version_calculator'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/app_version'

describe Fastlane::Calculators::MarketingVersionCalculator do
  describe 'bumps the version number when using marketing versioning' do
    context 'when the minor version is not 9' do
      it 'increments the minor version when the minor version is less than 9' do
        version = Fastlane::Models::AppVersion.new(13, 5, 1, 1)
        calculator = described_class.new(version)
        bumped_version = calculator.calculate_next_release_version.to_s
        expect(bumped_version).to eq('13.6.0.0')
      end

      it 'increments the minor version when the minor version is greater than 9' do
        version = Fastlane::Models::AppVersion.new(13, 11, 1, 1)
        calculator = described_class.new(version)
        bumped_version = calculator.calculate_next_release_version.to_s
        expect(bumped_version).to eq('13.12.0.0')
      end
    end

    context 'when the minor number is 9' do
      it 'increments the major version and sets the minor version to 0 ' do
        version = Fastlane::Models::AppVersion.new(13, 9, 1, 1)
        calculator = described_class.new(version)
        bumped_version = calculator.calculate_next_release_version.to_s
        expect(bumped_version).to eq('14.0.0.0')
      end
    end
  end
end