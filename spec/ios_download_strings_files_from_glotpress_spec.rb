require 'spec_helper'
require 'tmpdir'

describe Fastlane::Actions::IosDownloadStringsFilesFromGlotpressAction do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations', 'ios_generate_strings_file_from_code') }
  let(:gp_fake_url) { 'https://stub.glotpress.com/rspec-fake-project' }
  let(:locales_subset) { { 'fr-FR': 'fr', 'zh-cn': 'zh-Hans' } }

  def gp_stub(locale:, query:)
    stub_request(:get, "#{gp_fake_url}/#{locale}/default/export-translations/").with(query: query)
  end

  describe 'downloading export files from GlotPress' do
    def test_gp_download(filters:, tablename:, expected_gp_params:)
      Dir.mktmpdir('a8c-release-toolkit-tests-') do |tmp_dir|
        # Arrange
        stub_fr = gp_stub(locale: 'fr-FR', query: expected_gp_params).to_return(body: '"key" = "fr-copy";')
        stub_zh = gp_stub(locale: 'zh-cn', query: expected_gp_params).to_return(body: '"key" = "zh-copy";')

        # Act
        # Note: The use of `.compact` here allows us to remove the keys (like `table_basename` and `filters`) from the `Hash` whose values are `nil`,
        # so that we don't include those parameters at all in the action's call site -- making them use the default value from their respective
        # `ConfigItem` (as opposed to passing a value of `nil` explicitly and overwrite the default value, which is not what we want to test).
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
        tablename: 'MyApp',
        expected_gp_params: { 'filters[status]': 'current', format: 'strings' }
      )
    end
  end

  describe 'error handling' do
    it 'shows an error if an invalid locale is provided (404)' do
      Dir.mktmpdir('a8c-release-toolkit-tests-') do |tmp_dir|
        # Arrange
        stub = gp_stub(locale: 'unknown-locale', query: { 'filters[status]': 'current', format: 'strings' }).to_return(status: [404, 'Not Found'])
        error_messages = []
        allow(FastlaneCore::UI).to receive(:error) { |message| error_messages.append(message) }
        allow(FastlaneCore::UI).to receive(:confirm).and_return(false) # as we will be asked if we want to retry when getting a network error

        # Act
        run_described_fastlane_action(
          project_url: gp_fake_url,
          locales: { 'unknown-locale': 'Base' },
          download_dir: tmp_dir
        )

        # Assert
        expect(stub).to have_been_made.once
        expect(File).not_to exist(File.join(tmp_dir, 'Base.lproj', 'Localizable.strings'))
        expect(error_messages).to eq(["Error downloading locale `unknown-locale` — 404 Not Found (#{gp_fake_url}/unknown-locale/default/export-translations/?filters%5Bstatus%5D=current&format=strings)"])
      end
    end

    it 'shows an error if the file cannot be written in the destination' do
      # Arrange
      download_dir = '/these/are/not/the/dirs/you/are/looking/for/'

      # Act
      act = lambda do
        run_described_fastlane_action(
          project_url: gp_fake_url,
          locales: { 'fr-FR': 'fr' },
          download_dir: download_dir
        )
      end

      # Assert
      # Note: FastlaneError is the exception raised by UI.user_error!
      expect { act.call }.to raise_error(FastlaneCore::Interface::FastlaneError, "The parent directory `#{download_dir}` (which contains all the `*.lproj` subdirectories) must already exist")
    end

    it 'reports if a downloaded file is not a valid `.strings` file' do
      Dir.mktmpdir('a8c-release-toolkit-tests-') do |tmp_dir|
        # Arrange
        stub = gp_stub(locale: 'fr-FR', query: { 'filters[status]': 'current', format: 'strings' }).to_return(body: 'some invalid strings file content')
        error_messages = []
        allow(FastlaneCore::UI).to receive(:error) { |message| error_messages.append(message) }

        # Act
        run_described_fastlane_action(
          project_url: gp_fake_url,
          locales: { 'fr-FR': 'fr' },
          download_dir: tmp_dir
        )

        # Assert
        expect(stub).to have_been_made.once
        file = File.join(tmp_dir, 'fr.lproj', 'Localizable.strings')
        expect(File).to exist(file)
        expected_error = 'Property List error: Unexpected character s at line 1 / JSON error: JSON text did not start with array or object and option to allow fragments not set.'
        expect(error_messages.count).to eq(1)
        expect(error_messages.first).to start_with("Error while validating the file exported from GlotPress (`#{file}`) - #{file}: #{expected_error}") # Different versions of `plutil` might append the line/column as well, but not all.
      end
    end

    it 'reports if a downloaded file has empty translations' do
      Dir.mktmpdir('a8c-release-toolkit-tests-') do |tmp_dir|
        # Arrange
        stub = gp_stub(locale: 'fr-FR', query: { 'filters[status]': 'current', format: 'strings' })
               .to_return(body: ['"key1" = "value1";', '"key2" = "";', '"key3" = "";', '/* translators: use "" quotes please */', '"key4" = "value4";'].join("\n"))
        error_messages = []
        allow(FastlaneCore::UI).to receive(:error) { |message| error_messages.append(message) }

        # Act
        run_described_fastlane_action(
          project_url: gp_fake_url,
          locales: { 'fr-FR': 'fr' },
          download_dir: tmp_dir
        )

        # Assert
        expect(stub).to have_been_made.once
        file = File.join(tmp_dir, 'fr.lproj', 'Localizable.strings')
        expect(File).to exist(file)
        expected_error = <<~MSG.chomp
          Found empty translations in `#{file}` for the following keys: ["key2", "key3"].
          This is likely a GlotPress bug, and will lead to copies replaced by empty text in the UI.
          Please report this to the GlotPress team, and fix the file locally before continuing.
        MSG
        expect(error_messages).to eq([expected_error])
      end
    end

    it 'does not report invalid downloaded files if `skip_file_validation:true`' do
      Dir.mktmpdir('a8c-release-toolkit-tests-') do |tmp_dir|
        # Arrange
        stub = gp_stub(locale: 'fr-FR', query: { 'filters[status]': 'current', format: 'strings' }).to_return(body: 'some invalid strings file content')
        error_messages = []
        allow(FastlaneCore::UI).to receive(:error) { |message| error_messages.append(message) }

        # Act
        act = lambda do
          run_described_fastlane_action(
            project_url: gp_fake_url,
            locales: { 'fr-FR': 'fr' },
            download_dir: tmp_dir,
            skip_file_validation: true
          )
        end

        # Assert
        expect { act.call }.not_to raise_error
        expect(stub).to have_been_made.once
        file = File.join(tmp_dir, 'fr.lproj', 'Localizable.strings')
        expect(File).to exist(file)
        expect(error_messages).to eq([])
      end
    end
  end
end
