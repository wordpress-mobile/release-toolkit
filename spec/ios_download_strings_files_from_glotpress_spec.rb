require 'spec_helper'
require 'tmpdir'

Locale = Struct.new(:name)

describe Fastlane::Actions::IosDownloadStringsFilesFromGlotpressAction do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations', 'ios_generate_strings_file_from_code') }

  describe 'downloading export files from GlotPress' do
    it 'downloads all the locales into the expected directories'
    it 'uses the proper filters when exporting the files from GlotPress'
    it 'uses a custom table name for the `.strings` files if provided'
  end

  describe 'error handling' do
    it 'shows an error if an invalid locale is provided (404)'
    it 'shows an error if the file cannot be written in the destination'
    it 'reports if a downloaded file is invalid by default'
    it 'does not report invalid downloaded files if skip_file_validation:true'
  end
end
