require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::DerivedOptionTwoBuildCodeFormatter do
  describe 'derives a build code from an AppVersion object' do
    it 'derives the build code from version numbers that are single digits' do
      version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
      build_code_string = described_class.new.build_code(version: version)
      expect(build_code_string.to_s).to eq('12304')
    end

    it 'derives the build code from version numbers that are two digits' do
      version = Fastlane::Models::AppVersion.new(12, 34, 56, 78)
      build_code_string = described_class.new.build_code(version: version)
      expect(build_code_string.to_s).to eq('12345678')
    end
  end
end
