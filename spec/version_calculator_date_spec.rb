require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::DateVersionCalculator do
  describe 'calculates the next release version when using date versioning' do
    context 'when the current month is not December' do
      it 'increments the minor version number without prompting the user' do
        allow(Time).to receive(:now).and_return(Time.new(2024, 4, 15))
        version = Fastlane::Models::AppVersion.new(2024, 13, 1, 1)
        bumped_version = described_class.new.next_release_version(version: version)
        expect(bumped_version.to_s).to eq('2024.14.0.0')
      end
    end

    context 'when the current month is December' do
      context 'when the release is the first release of the next year' do
        it 'increments the major version number and sets the minor version number to 1' do
          allow(Time).to receive(:now).and_return(Time.new(2023, 12, 3))
          allow(FastlaneCore::UI).to receive(:confirm).and_return(true)
          version = Fastlane::Models::AppVersion.new(2023, 30, 1, 2)
          bumped_version = described_class.new.next_release_version(version: version)
          expect(bumped_version.to_s).to eq('2024.1.0.0')
        end
      end

      context 'when the release is not the first release of the next year' do
        it 'increments the minor version number' do
          allow(Time).to receive(:now).and_return(Time.new(2023, 12, 1))
          allow(FastlaneCore::UI).to receive(:confirm).and_return(false)
          version = Fastlane::Models::AppVersion.new(2023, 30, 1, 2)
          bumped_version = described_class.new.next_release_version(version: version)
          expect(bumped_version.to_s).to eq('2023.31.0.0')
        end
      end
    end
  end

  describe 'calculates the previous release version when using date versioning' do
    context 'when the minor version is not 1' do
      it 'decrements the minor version number' do
        version = Fastlane::Models::AppVersion.new(2023, 30, 1, 2)
        previous_version = described_class.new.previous_release_version(version: version)
        expect(previous_version.to_s).to eq('2023.29.0.0')
      end
    end

    context 'when the minor version is 1' do
      it 'prompts the user to input the minor number of the previous release' do
        allow(FastlaneCore::UI).to receive(:prompt).and_return('29')
        version = Fastlane::Models::AppVersion.new(2023, 1, 1, 1)
        previous_version = described_class.new.previous_release_version(version: version)
        expect(previous_version.to_s).to eq('2022.29.0.0')
      end
    end
  end
end