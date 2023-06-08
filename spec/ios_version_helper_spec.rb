require_relative './spec_helper'

describe Fastlane::Helper::Ios::VersionHelper do
  describe 'calculates_the_next_release_version' do
    context 'when using calendar_versioning' do
      it 'increments the minor version number' do
        version = '1995.5'
        next_version = described_class.calc_next_release_version(version, 'calendar')
        expect(next_version).to eq('1995.6')
      end

      it 'increments the major version number and resets the minor version number to 1 if it is the first release of the next year' do
        allow(Time).to receive(:now).and_return(Time.new(2023, 12, 3))
        allow(FastlaneCore::UI).to receive(:confirm).and_return(true)
        version = '1995.26'
        next_version = described_class.calc_next_release_version(version, 'calendar')
        expect(next_version).to eq('1996.1')
      end

      it 'does not increment the major version number if it is not the first release of the next year' do
        allow(Time).to receive(:now).and_return(Time.new(2023, 12, 1))
        allow(FastlaneCore::UI).to receive(:confirm).and_return(false)
        version = '1995.26'
        next_version = described_class.calc_next_release_version(version, 'calendar')
        expect(next_version).to eq('1995.27')
      end
    end

    context 'when using marketing versioning' do
      it 'when using marketing versioning if the minor version number is 9 or less' do
        version = '1.0'
        next_version = described_class.calc_next_release_version(version, 'marketing')
        expect(next_version).to eq('1.1')
      end

      it 'resets the minor version number to 0 and increments the major version number if the minor number is 9' do
        version = '1.9'
        next_version = described_class.calc_next_release_version(version, 'marketing')
        expect(next_version).to eq('2.0')
      end

      it 'does not reset the minor version number if it is less than 10' do
        version = '1.5'
        next_version = described_class.calc_next_release_version(version, 'marketing')
        expect(next_version).to eq('1.6')
      end
    end

    context 'when an invalid versioning scheme is provided' do
      it 'raises an error' do
        version = '1.0'
        error_message = "Please set the versioning scheme to 'calendar' or 'marketing'"
        expect do
          described_class.calc_next_release_version(version, 'invalid_scheme')
        end.to raise_error(FastlaneCore::Interface::FastlaneError, error_message)
      end
    end
  end
end
