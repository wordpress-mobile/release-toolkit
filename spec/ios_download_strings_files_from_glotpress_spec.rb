require 'spec_helper'
require 'tmpdir'

describe Fastlane::Actions::IosDownloadStringsFilesFromGlotpressAction do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations', 'ios_generate_strings_file_from_code') }

  describe 'downloading export files from GlotPress' do
    let(:gp_fake_url) { 'https://stub.glotpress.com/rspec-fake-project' }
    let(:locales_subset) { {'fr-FR': 'fr', 'zh-cn': 'zh-Hans' } }

    def gp_stub(locale:, query:)
      stub_request(:get, "#{gp_fake_url}/#{locale}/default/export-translations").with(query: query)
    end

    def test_gp_download(filters:, tablename:, expected_gp_params:)
      Dir.mktmpdir('a8c-release-toolkit-tests-') do |tmp_dir|
        # Arrange
        stub_fr = gp_stub(locale: 'fr-FR', query: expected_gp_params).to_return(body: '"key" = "fr-copy";')
        stub_zh = gp_stub(locale: 'zh-cn', query: expected_gp_params).to_return(body: '"key" = "zh-copy";')

        # Act
        run_described_fastlane_action({
          project_url: gp_fake_url,
          locales: locales_subset,
          download_dir: tmp_dir,
          table_basename: tablename,
          filters: filters
        }.compact)

        # Assert
        expect(stub_fr).to have_been_made.once
        file_fr = File.join(tmp_dir, 'fr.lproj', "#{tablename || 'Localizable'}.strings")
        expect(File).to exist(file_fr)
        expect(File.read(file_fr)).to eq('"key" = "fr-copy";')

        expect(stub_zh).to have_been_made.once
        file_zh = File.join(tmp_dir, 'zh-Hans.lproj', "#{tablename || 'Localizable'}.strings")
        expect(File).to exist(file_zh)
        expect(File.read(file_zh)).to eq('"key" = "zh-copy";')
      end
    end

    it 'downloads all the locales into the expected directories' do
      test_gp_download(filters: nil, tablename: nil, expected_gp_params: { 'filters[status]': 'current', format: 'strings' })
    end

    it 'uses the proper filters when exporting the files from GlotPress' do
      test_gp_download(
        filters: { term: 'foo', status: 'review' },
        tablename: nil,
        expected_gp_params: { 'filters[term]': 'foo', 'filters[status]': 'review', format: 'strings' }
      )
    end

    it 'uses a custom table name for the `.strings` files if provided' do
      test_gp_download(
        filters: nil,
        tablename: "MyApp",
        expected_gp_params: { 'filters[status]': 'current', format: 'strings' }
      )
    end
  end

  describe 'error handling' do
    it 'shows an error if an invalid locale is provided (404)'
    it 'shows an error if the file cannot be written in the destination'
    it 'reports if a downloaded file is invalid by default'
    it 'does not report invalid downloaded files if skip_file_validation:true'
  end
end
