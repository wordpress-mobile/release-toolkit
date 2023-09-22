require 'spec_helper'

describe Fastlane::Models::BuildCode do
  describe '#initialize' do
    it 'sets the build code to the provided value' do
      build_code = described_class.new('135')
      expect(build_code.build_code.to_s).to eq('135')
    end

    it 'sets the build code to 0 if a non-numerical string is provided' do
      build_code = described_class.new('ABC123')
      expect(build_code.build_code.to_s).to eq('0')
    end

    it 'raises an error if a nil build code is provided' do
      expect { described_class.new(nil) }
        .to raise_error(
          FastlaneCore::Interface::FastlaneError,
          'Build code cannot be nil'
        )
    end
  end

  describe '#to_s' do
    it 'returns the build code as a string' do
      build_code = described_class.new(123)
      expect(build_code.to_s).to eq('123')
    end
  end
end
