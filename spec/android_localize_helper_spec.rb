require 'spec_helper.rb'
require 'fileutils'
require 'tmpdir'
require 'nokogiri'

TEST_LOCALES_MAP = [
  { glotpress: 'pt-br', android: 'pt-rBR' },
  { glotpress: 'zh-cn', android: 'zh-rCN' },
  { glotpress: 'fr', android: 'fr' },
].freeze

describe Fastlane::Helper::Android::LocalizeHelper do
  let(:fixtures_dir) { File.join(__dir__, 'test-data', 'translations', 'glotpress-download') }
  let(:stubs_dir) { File.join(fixtures_dir, 'stubs') }
  let(:expected_dir) { File.join(fixtures_dir, 'expected') }
  let(:tmpdir) { Dir.mktmpdir('a8c-android-localize-helper-spec-') }

  after do
    FileUtils.remove_entry tmpdir
  end

  ### Helper Methods

  def stub_file(code)
    File.join(stubs_dir, "#{code}.xml")
  end

  def expected_file(code)
    File.join(expected_dir, code.nil? ? 'values' : "values-#{code}", 'strings.xml')
  end

  def generated_file(code)
    File.join(tmpdir, code.nil? ? 'values' : "values-#{code}", 'strings.xml')
  end

  ### Unit Tests

  describe 'create_available_languages_file' do
    it 'contains the proper locale codes' do
      FileUtils.mkdir_p(File.join(tmpdir, 'values'))
      described_class.create_available_languages_file(
        res_dir: tmpdir,
        locale_codes: %w[en-rUS es pt-rBR it zh-rCN zh-rTW fr]
      )

      generated_file = File.join(tmpdir, 'values', 'available_languages.xml')
      expected_file = File.join(expected_dir, 'values', 'available_languages.xml')
      expect(File.exist?(generated_file)).to be(true)
      expect(File.read(generated_file).strip).to eq(File.read(expected_file).strip)
    end
  end

  describe 'download_from_glotpress' do
    let(:gp_fake_url) { 'https://stub.glotpress.com/rspec-fake-project/' }

    context 'with default filter' do
      let(:warning_messages) { [] }

      before do
        # Arrange: Configure stubs for GlotPress network requests for each locale
        Dir[File.join(stubs_dir, '*.xml')].each do |path|
          # Each file in stubs_dir is a `{locale_code}.xml` whose content is what we want to use as stub for glotpress requests to `locale_code`
          locale_code = File.basename(path, '.xml')
          url = "#{gp_fake_url.chomp('/')}/#{locale_code}/default/export-translations?filters%5Bstatus%5D=current&format=android"
          stub_request(:get, url).to_return(status: 200, body: File.read(path))
        end

        # Arrange: copy original values/strings.xml file to tmpdir
        FileUtils.mkdir_p(File.dirname(generated_file(nil)))
        FileUtils.cp(expected_file(nil), generated_file(nil))

        allow(FastlaneCore::UI).to receive(:important) do |message|
          warning_messages << message
        end

        # Act
        described_class.download_from_glotpress(
          res_dir: tmpdir,
          glotpress_project_url: gp_fake_url,
          locales_map: TEST_LOCALES_MAP
        )
      end

      it 'tests all the locales we have fixtures for' do
        # Ensure we don't forget to update the locales map if we add more stubs in the future, and vice-versa
        expect(TEST_LOCALES_MAP.map { |h| "#{h[:glotpress]}.xml" }.sort).to eq(Dir.children(stubs_dir).sort)
        expect(TEST_LOCALES_MAP.map { |h| "values-#{h[:android]}" }.sort).to eq(Dir.children(expected_dir).reject { |d| d == 'values' }.sort)
      end

      describe 'generates the expected files' do
        TEST_LOCALES_MAP.each do |h|
          it "for #{h[:android]}" do
            expected_file = expected_file(h[:android])
            generated_file = generated_file(h[:android])
            expect(File.exist?(generated_file)).to be(true)
            expect(File.read(generated_file).chomp).to eq(File.read(expected_file).chomp)
          end
        end
      end

      describe 'applies content substitutions' do
        shared_examples 'substitutions' do |xpath|
          it 'has at least one fixture with text to be substituted' do
            # This ensures that even if we modify the fixtures in the future, we will still have a case which tests this
            gp_xml = File.open(stub_file('pt-br')) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
            gp_node = gp_xml.xpath(xpath).first
            expect(gp_node.content).to include('...')
          end

          TEST_LOCALES_MAP.each do |h|
            it "has the text substituted in #{h[:android]}" do
              final_xml = File.open(generated_file(h[:android])) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
              final_node = final_xml.xpath(xpath).first
              expect(final_node.content).to include('…')
              expect(final_node.content).not_to include('...')
            end
          end
        end

        context 'with //string tags' do
          include_examples 'substitutions', "/resources/string[@name='shipping_label_payments_saving_dialog_message']"
        end

        context 'with //string-array/item tags' do
          include_examples 'substitutions', "/resources/string-array[@name='order_list_tabs']/item[1]"
        end
      end

      it 'replicates formatted="false" attribute to generated files' do
        orig_xml = File.open(generated_file(nil)) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
        pt_xml = File.open(generated_file('pt-rBR')) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }

        orig_node = orig_xml.xpath("/resources/string[@formatted='false']").first
        expect(orig_node).not_to be_nil

        pt_node = pt_xml.xpath("/resources/string[@name='#{orig_node['name']}']").first
        expect(pt_node).not_to be_nil
        expect(pt_node['formatted']).to eq(orig_node['formatted'])
      end

      it 'warns about %% usage on tags with formatted="false"' do
        fr_xml = File.open(generated_file('fr')) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
        node = fr_xml.xpath("/resources/string[@formatted='false']").first

        expect(node).not_to be_nil
        expect(node.content).to include('%%')
        expect(node['name']).not_to be_nil
        expect(warning_messages).to include(%(Warning: [fr] translation for '#{node['name']}' has attribute formatted=false, but still contains escaped '%%' in translation.))
      end
    end

    context 'with custom filters' do
      it 'uses filters during export when custom ones are provided' do
        # Arrange: copy original values/strings.xml file to tmpdir
        FileUtils.mkdir_p(File.dirname(generated_file(nil)))
        FileUtils.cp(expected_file(nil), generated_file(nil))

        # Arrange: Prepare request stubs
        custom_gp_urls = TEST_LOCALES_MAP.map do |locale|
          "#{gp_fake_url.chomp('/')}/#{locale[:glotpress]}/default/export-translations?filters%5Bstatus%5D=custom-status&filters%5Bwarnings%5D=yes&format=android"
        end
        custom_gp_urls.each do |url|
          stub_request(:get, url)
        end

        # Act
        described_class.download_from_glotpress(
          res_dir: tmpdir,
          glotpress_project_url: gp_fake_url,
          glotpress_filters: { status: 'custom-status', warnings: 'yes' },
          locales_map: TEST_LOCALES_MAP
        )

        # Assert: Check requests were done
        custom_gp_urls.each do |url|
          assert_requested(:get, url, times: 1)
        end
      end

      it 'merges the various exports with different filters together' do
        # Arrange: copy original values/strings.xml file to tmpdir
        FileUtils.mkdir_p(File.dirname(generated_file(nil)))
        FileUtils.cp(expected_file(nil), generated_file(nil))

        # Arrange: Prepare request stubs
        statuses = %w[current waiting fuzzy]
        statuses.each do |status|
          stub_path = File.join(fixtures_dir, 'filters', "#{status}.xml")
          stub_request(:get, "#{gp_fake_url.chomp('/')}/fakegploc/default/export-translations?filters%5Bstatus%5D=#{status}&format=android")
            .to_return(status: 200, body: File.read(stub_path))
        end

        # Act
        filters = statuses.map { |s| { status: s } }
        described_class.download_from_glotpress(
          res_dir: tmpdir,
          glotpress_project_url: gp_fake_url,
          glotpress_filters: filters,
          locales_map: [{ glotpress: 'fakegploc', android: 'fakeanloc' }]
        )

        # Assert: Check generated merged file
        generated_file_path = generated_file('fakeanloc')
        expected_merged_content = File.read(File.join(fixtures_dir, 'filters', 'merged.xml'))
        expect(File.exist?(generated_file_path)).to be(true)
        expect(File.read(generated_file_path)).to eq(expected_merged_content)
      end
    end
  end
end
