require 'spec_helper'
require_relative '../lib/fastlane/plugin/wpmreleasetoolkit/models/build_code'

describe Fastlane::Models::BuildCode do
  describe '#initialize' do
    it 'should set the build code' do
      build_code = Fastlane::Models::BuildCode.new('ABC123')
      expect(build_code.build_code).to eq('ABC123')
    end
  end

  describe '#to_s' do
    it 'should return the build code as a string' do
      build_code = Fastlane::Models::BuildCode.new(123)
      expect(build_code.to_s).to eq('123')
    end

    it 'should handle nil values' do
      build_code = Fastlane::Models::BuildCode.new(nil)
      expect(build_code.to_s).to eq('')
    end
  end
end
