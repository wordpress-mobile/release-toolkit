require 'spec_helper.rb'
require 'fileutils'
require 'tmpdir'
require 'yaml'
require 'nokogiri'

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

    LOCALES_MAP = [
      { glotpress: 'pt-br', android: 'pt-rBR'},
      { glotpress: 'zh-cn', android: 'zh-rCN'},
      { glotpress: 'fr', android: 'fr' },
    ]

    def stub_file(code)
      File.join(@stubs_dir, "#{code}.xml")
    end

    def expected_file(code)
      File.join(@expected_dir, code.nil? ? 'values' : "values-#{code}", 'strings.xml')
    end

    it 'tests all locales' do
      # Ensure we don't forget to update the locales map if we add more stubs in the future, and vice-versa
      expect(LOCALES_MAP.map { |h| "#{h[:glotpress]}.xml" }.sort).to eq(Dir.children(@stubs_dir).sort)
      expect(LOCALES_MAP.map { |h| "values-#{h[:android]}" }.sort).to eq(Dir.children(@expected_dir).reject { |d| d == 'values' }.sort)
    end

    it 'generates expected files' do      
      Dir.mktmpdir('a8c-android-localize-helper-spec-') do |tmpdir|
        # Arrange: Configure stubs for GlotPress network requests for each locale
        gp_fake_url = 'https://stub.glotpress.com/rspec-fake-project/'
        Dir[File.join(@stubs_dir, '*.xml')].each do |path|
          # Each file in stubs_dir is a `{locale_code}.xml` whose content is what we want to use as stub for glotpress requests to `locale_code`
          locale_code = File.basename(path, '.xml')
          url = "#{gp_fake_url.chomp('/')}/#{locale_code}/default/export-translations?filters%5Bstatus%5D=current&format=android"
          stub_request(:get, url).to_return(status: 200, body: File.read(path))
        end

        # Arrange: copy original values/strings.xml file to tmpdir
        FileUtils.mkdir_p(File.join(tmpdir, 'values'))
        FileUtils.cp(expected_file(nil), File.join(tmpdir, 'values', 'strings.xml'))

        # Act
        described_class.download_from_glotpress(
          res_dir: tmpdir,
          glotpress_project_url: gp_fake_url,
          locales_map: LOCALES_MAP
        )
      
        # Assert: The entry containing formatted=false with '%%' in text does generate a warning
        # @todo: expect(Fastlane::UI).to receive(:important).with('…the message…')

        # Assert: Content of generated files matches the expectated files
        Dir.children(@expected_dir).each do |dir_name|
          expected_file = File.join(@expected_dir, dir_name, 'strings.xml')
          generated_file = File.join(tmpdir, dir_name, 'strings.xml')
          expect(File.exist?(generated_file)).to be(true)
          expect(File.read(generated_file).chomp).to eq(File.read(expected_file).chomp)
        end
      end
    end

    def check_substitutions_in_node(xpath)
      # Check that at least one (pt-br) stub of the XMLs returned by GlotPress has a node with '...' that needs being substituted
      gp_xml = File.open(stub_file('pt-br')) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
      gp_node = gp_xml.xpath(xpath).first
      expect(gp_node.content).to include('...')

      # Check that the same string in all the final, generated XMLs has that '...' substituted to '…'
      LOCALES_MAP.each do |h|
        final_xml = File.open(expected_file(h[:android])) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
        final_node = final_xml.xpath(xpath).first
        expect(final_node.content).to include('…')
        expect(final_node.content).not_to include('...')
      end
    end

    it 'replaces ... with … in string tags' do
      string_node_xpath = "/resources/string[@name='shipping_label_payments_saving_dialog_message']"
      check_substitutions_in_node(string_node_xpath)
    end

    it 'replaces ... with … in string-array/item tags' do
      item_node_xpath = "/resources/string-array[@name='order_list_tabs']/item[1]"
      check_substitutions_in_node(item_node_xpath)
    end

    it 'has a fixture with formatted=false tag containing accidentally escaped %%' do
      path = expected_file('fr')
      xpath = "/resources/string[@formatted='false']"

      xml = File.open(path) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
      node = xml.xpath(xpath).first
      
      expect(node).not_to be_nil
      expect(node.content).to include('%%')
      # The fact that we will trigger a warning during generation is tested by the "generates expected files" example
    end

    it 'replicates formatted=false attribute to generated files' do
      orig_xml = File.open(expected_file(nil)) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
      final_xml = File.open(expected_file('pt-rBR')) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }

      orig_node = orig_xml.xpath("/resources/string[@formatted='false']").first
      expect(orig_node).not_to be_nil

      final_node = final_xml.xpath("/resources/string[@name='#{orig_node['name']}']").first
      expect(final_node).not_to be_nil
      expect(final_node['formatted']).to eq(orig_node['formatted'])
    end

    # @todo Tweak one of the stubs and expected to have a formatted=false but also '%%', then enable `expect(Fastlane::UI)…` line below
  end
end
