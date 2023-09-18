require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/versioning/calculators/date_version_calculator'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/versioning/calculators/version_calculator'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/app_version'

describe Fastlane::Wpmreleasetoolkit::Versioning::DateVersionCalculator do
  describe 'bumps the version number when using date versioning' do
    context 'when the current month is not December' do
      it 'increments the minor version number without prompting the user' do
        allow(Time).to receive(:now).and_return(Time.new(2024, 4, 15))
        version = Fastlane::Models::AppVersion.new(2005, 13, 1, 1)
        calculator = described_class.new(version)
        bumped_version = calculator.calculate_next_release_version.to_s
        expect(bumped_version).to eq('2005.14.0.0')
      end
    end

    context 'when the current month is December' do
      context 'when the release is the first release of the next year' do
        it 'increments the major version number and sets the minor version number to 1' do
          allow(Time).to receive(:now).and_return(Time.new(2023, 12, 3))
          allow(FastlaneCore::UI).to receive(:confirm).and_return(true)
          version = Fastlane::Models::AppVersion.new(1999, 30, 1, 2)
          calculator = described_class.new(version)
          bumped_version = calculator.calculate_next_release_version.to_s
          expect(bumped_version).to eq('2000.1.0.0')
        end
      end

      context 'when the release is not the first release of the next year' do
        it 'increments the minor version number' do
          allow(Time).to receive(:now).and_return(Time.new(2023, 12, 1))
          allow(FastlaneCore::UI).to receive(:confirm).and_return(false)
          version = Fastlane::Models::AppVersion.new(1999, 30, 1, 2)
          calculator = described_class.new(version)
          bumped_version = calculator.calculate_next_release_version.to_s
          expect(bumped_version).to eq('1999.31.0.0')
        end
      end
    end
  end
end
