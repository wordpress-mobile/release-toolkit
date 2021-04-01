require 'spec_helper.rb'
require 'fileutils'
require 'tmpdir'
require 'yaml'

describe Fastlane::Helper::Android::LocalizeHelper do
  it 'creates the available_languages.xml file with proper locale codes' do
    Dir.mktmpdir('a8c-android-localizehelper-tests-') do |tmpdir|
      FileUtils.mkdir_p(File.join(tmpdir, 'values'))
      described_class.create_available_languages_file(
        res_dir: tmpdir,
        locale_codes: %w[en-rUS es pt-rBR it zh-rCN zh-rTW fr]
      )
      path = File.join(tmpdir, 'values', 'available_languages.xml')
      expected_content = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <!--Warning: Auto-generated file, do not edit.-->
        <resources>
          <string-array name="available_languages" translatable="false">
            <item>en_US</item>
            <item>es</item>
            <item>pt_BR</item>
            <item>it</item>
            <item>zh_CN</item>
            <item>zh_TW</item>
            <item>fr</item>
          </string-array>
        </resources>        
      XML
      expect(File.exist?(path)).to be(true)
      expect(File.read(path).strip).to eq(expected_content.strip)
    end
  end

  describe 'download_from_glotpress' do
    before do
      fixtures_dir = File.join(__dir__, 'test-data', 'translations', 'glotpress-download')
      @stubs_dir = File.join(fixtures_dir, 'stubs')
      @expected_dir = File.join(fixtures_dir, 'expected')
    end

    it 'replaces ... with … in string tags' do
      # @todo Check stubs/ contains a string tag with '...'
      # @todo Check corresponding expected/ file contains same tag with '…'
    end

    it 'replaces ... with … in string-array/item tags' do
      # @todo Check stubs/ contains an item tag with '...'
      # @todo Check corresponding expected/ file contains same tag with '…'
    end

    it 'replicates formatted=false attribute to generated files' do
      # @todo Check stubs/ contains a tag with formatted=false
      # @todo Check expected/ contains corresponding tag also with formatted=false
    end

    # @todo Add more translations than just pt-rBR
    # @todo Tweak one of the stubs and expected to have a formatted=false but also '%%', then enable `expect(Fastlane::UI)…` line below

    it 'generates files with proper post-processing' do      
      Dir.mktmpdir('a8c-android-localize-helper-spec-') do |tmpdir|
        # Arrange: Configure stubs for network requests of each locale
        gp_fake_url = 'https://stub.glotpress.com/rspec-fake-project/'
        Dir.children(@stubs_dir).each do |file_name|
          # Each file in stubs_dir is a `locale_code.xml` with content for stubbing glotpress requests to `locale_code`
          locale_code = File.basename(file_name, '.xml')
          url = "#{gp_fake_url.chomp('/')}/#{locale_code}/default/export-translations?filters%5Bstatus%5D=current&format=android"
          path = File.join(@stubs_dir, file_name)
          stub_request(:get, url).to_return(status: 200, body: File.read(path))
        end

        # Arrange: copy original values/strings.xml file to tmp dir
        FileUtils.mkdir_p(File.join(tmpdir, 'values'))
        FileUtils.cp(File.join(@expected_dir, 'values', 'strings.xml'), File.join(tmpdir, 'values', 'strings.xml'))

        # Act
        locales = [
          { glotpress: 'pt-br', android: 'pt-rBR'}
        ]  
        described_class.download_from_glotpress(
          res_dir: tmpdir,
          glotpress_project_url: gp_fake_url,
          locales_map: locales
        )
      
        # Assert
        # @todo: expect(Fastlane::UI).to receive(:important).with('…the message…')
        Dir.children(@expected_dir).each do |dir_name|
          expected_file = File.join(@expected_dir, dir_name, 'strings.xml')
          generated_file = File.join(tmpdir, dir_name, 'strings.xml')
          expect(File.exist?(generated_file)).to be(true)
          expect(File.read(generated_file).chomp).to eq(File.read(expected_file).chomp)
        end
      end
    end
  end
end
