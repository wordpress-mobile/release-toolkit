require 'spec_helper'

describe Fastlane::Wpmreleasetoolkit::Versioning::SimpleBuildCodeFormatter do
  describe 'formats a BuildCode object as a build code' do
    it 'returns the integer build code as a string' do
      build_code = Fastlane::Models::BuildCode.new(735)
      build_code_string = described_class.new.build_code(build_code: build_code)
      expect(build_code_string.to_s).to eq('735')
    end
  end
end
