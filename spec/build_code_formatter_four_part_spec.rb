require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::FourPartBuildCodeFormatter do
  describe 'formats an AppVersion object as a four part build code' do
    it 'returns the four part build code as a string' do
      version = Fastlane::Models::AppVersion.new(1, 2, 3, 4)
      build_code_string = described_class.new.build_code(version: version)
      expect(build_code_string.to_s).to eq('1.2.3.4')
    end
  end
end
