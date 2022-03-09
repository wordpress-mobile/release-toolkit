require_relative './spec_helper'

describe Fastlane::Helper::Ios::L10nHelper do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations', 'ios_l10n_helper') }

  def fixture(name)
    File.join(test_data_dir, name)
  end

  # Returns the `Encoding` instance guessed for that file. Useful to control that our fixtures are in the expected encoding when running tests.
  def file_encoding(path)
    File.read(path, mode: 'rb:BOM|UTF-8').encoding # Use BOM to determine encoding if present, fallback to UTF8
  end

  describe '#strings_file_type' do
    it 'detects an XML-formatted strings file' do
      xml_fixture = fixture('xml-format.strings')
      expect(described_class.strings_file_type(path: xml_fixture)).to eq(:xml)
    end

    it 'detects a binary-plist strings file' do
      bplist_fixture = fixture('bplist-format.strings')
      expect(described_class.strings_file_type(path: bplist_fixture)).to eq(:binary)
    end

    it 'detects a text-formatted strings file' do
      text_fixture = fixture('Localizable-utf16.strings')
      expect(described_class.strings_file_type(path: text_fixture)).to eq(:text)
    end

    it 'returns nil on a non-existing path' do
      expect(described_class.strings_file_type(path: '/invalid-path')).to be_nil
    end

    it 'returns nil on file that is not a strings file at all' do
      invalid_fixture = fixture('invalid-file.strings')
      expect(File).to exist(invalid_fixture)
      expect(described_class.strings_file_type(path: invalid_fixture)).to be_nil
    end
  end

  describe '#merge_strings' do
    # Ensuring we test this against input files which are using different encodings (UTF-16BE & UTF-8) is an important case to cover
    it 'properly merges 2 textual strings files with different encodings into a new one' do
      paths = { fixture('Localizable-utf16.strings') => nil, fixture('InfoPlist-utf8.strings') => nil }

      # Just making sure we don't accidentally change the encoding of the fixture files in the future
      expect(file_encoding(paths.keys[0])).to eq(Encoding::UTF_16BE)
      expect(file_encoding(paths.keys[1])).to eq(Encoding::UTF_8)

      Dir.mktmpdir('a8c-release-toolkit-l10n-helper-tests-') do |tmp_dir|
        output_file = File.join(tmp_dir, 'output.strings')
        described_class.merge_strings(paths: paths, output_path: output_file)
        expect(File.read(output_file)).to eq(File.read(fixture('expected-merged.strings')))
        expect(file_encoding(output_file)).to eq(Encoding::UTF_8)
      end
    end

    it 'properly merges 2 textual strings files in-place into the first one' do
      # This test is especially useful to check that if we use one of the input file as output, things will still work.
      paths = [fixture('Localizable-utf16.strings'), fixture('InfoPlist-utf8.strings')]
      Dir.mktmpdir('a8c-release-toolkit-l10n-helper-tests-') do |tmp_dir|
        paths.each { |f| FileUtils.cp(f, tmp_dir) }
        paths = paths.map { |f| [File.join(tmp_dir, File.basename(f)), nil] }.to_h
        described_class.merge_strings(paths: paths, output_path: paths.keys.first)
        expect(File.read(paths.keys.first)).to eq(File.read(fixture('expected-merged.strings')))
      end
    end

    it 'adds prefixes to string keys when merging files' do
      paths = {
        fixture('Localizable-utf16.strings') => 'main.',
        fixture('InfoPlist-utf8.strings') => 'infoplist.', # Useful case because it typically does not have quotes around keys
        fixture('non-latin-utf16.strings') => 'other.' # While this one does have quotes around its keys
      }
      Dir.mktmpdir('a8c-release-toolkit-l10n-helper-tests-') do |tmp_dir|
        output_file = File.join(tmp_dir, 'output.strings')
        described_class.merge_strings(paths: paths, output_path: output_file)
        expect(File.read(output_file)).to eq(File.read(fixture('expected-merged-prefixed.strings')))
      end
    end

    it 'returns duplicate keys found' do
      paths = { fixture('Localizable-utf16.strings') => nil, fixture('non-latin-utf16.strings') => nil }
      Dir.mktmpdir('a8c-release-toolkit-l10n-helper-tests-') do |tmp_dir|
        output_file = File.join(tmp_dir, 'output.strings')
        duplicates = described_class.merge_strings(paths: paths, output_path: output_file)
        expect(duplicates).to eq(%w[key1 key2])
      end
    end

    it 'raises if one of the strings file is not in textual format' do
      paths = { fixture('Localizable-utf16.strings') => nil, fixture('xml-format.strings') => nil }
      Dir.mktmpdir('a8c-release-toolkit-l10n-helper-tests-') do |tmp_dir|
        output_file = File.join(tmp_dir, 'output.strings')
        expect do
          described_class.merge_strings(paths: paths, output_path: output_file)
        end.to raise_exception(RuntimeError, "The file `#{paths.keys[1]}` is in xml format but we currently only support merging `.strings` files in text format.")
      end
    end

    it 'raises if any of the strings file does not exist' do
      paths = { fixture('Localizable-utf16.strings') => nil, '/these/are/not/the/droids/you/are/looking/for' => nil }
      Dir.mktmpdir('a8c-release-toolkit-l10n-helper-tests-') do |tmp_dir|
        output_file = File.join(tmp_dir, 'output.strings')
        expect do
          described_class.merge_strings(paths: paths, output_path: output_file)
        end.to raise_exception(RuntimeError, "The file `#{paths.keys[1]}` does not exist or is of unknown format.")
      end
    end
  end

  describe '#read_strings_file_as_hash' do
    it 'can read the content of a textual strings file' do
      file = fixture('Localizable-utf16.strings')
      expected_hash = { 'key1' => 'string 1', 'key2' => 'string 2️⃣', 'key3' => "string 3\non %d lines" }
      expect(described_class.read_strings_file_as_hash(path: file)).to eq(expected_hash)
    end

    it 'can read the content of an XML strings file' do
      file = fixture('xml-format.strings')
      expected_hash = { 'key1' => 'string 1 xml', 'key2' => 'string 2️⃣ xml', 'key3' => 'string 3 xml' }
      expect(described_class.read_strings_file_as_hash(path: file)).to eq(expected_hash)
    end

    it 'can read the content of a binary plist strings file' do
      file = fixture('bplist-format.strings')
      expected_hash = { 'key1' => 'string 1 bplist', 'key2' => 'string 2️⃣ bplist', 'key3' => 'string 3 bplist' }
      expect(described_class.read_strings_file_as_hash(path: file)).to eq(expected_hash)
    end

    it 'raises if trying to parse an invalid strings file' do
      file = fixture('invalid-file.strings')
      expect do
        described_class.read_strings_file_as_hash(path: file)
      end.to raise_exception(RuntimeError)
    end
  end

  describe '#generate_strings_file_from_hash' do
    it 'generates an XML strings file from a hash' do
      hash = {
        InfoKey1: 'Info String 1 translated',
        InfoKey2: 'Info String 2️⃣ translated',
        InfoKey3: 'Info String 3 translated'
      }
      Dir.mktmpdir('a8c-release-toolkit-l10n-helper-tests-') do |tmp_dir|
        output_file = File.join(tmp_dir, 'output.strings')
        expected_file = fixture('expected-generated.strings')
        described_class.generate_strings_file_from_hash(translations: hash, output_path: output_file)
        expect(File.read(output_file)).to eq(File.read(expected_file))
      end
    end

    # Reads non-latin content from UTF-16BE file and generates output file as UTF8
    it 'handles non-Latin, Unicode content properly' do
      non_latin_fixture = fixture('non-latin-utf16.strings')
      expected_file = fixture('expected-generated-non-latin.strings')

      # Just making sure we don't accidentally change the encoding of the fixture files in the future
      expect(file_encoding(non_latin_fixture)).to eq(Encoding::UTF_16BE)
      expect(file_encoding(expected_file)).to eq(Encoding::UTF_8)

      # 1. Read a textual strings file written in UTF-16 and containing non-latin chars
      translations = described_class.read_strings_file_as_hash(path: non_latin_fixture)
      # 2. Only keep specific keys from the hash (to simulate an extraction of the InfoPlist.strings key from GlotPress download)
      translations.slice!(*%w[diacritics emojis japanese])
      Dir.mktmpdir('a8c-release-toolkit-l10n-helper-tests-') do |tmp_dir|
        output_file = File.join(tmp_dir, 'output.strings')
        # 3. Generate XML strings file from the filtered hash
        described_class.generate_strings_file_from_hash(translations: translations, output_path: output_file)
        expect(File.read(output_file)).to eq(File.read(expected_file))
      end
    end
  end

  describe '#download_glotpress_export_file' do
    let(:gp_fake_url) { 'https://stub.glotpress.com/rspec-fake-project' }

    describe 'request query parameters' do
      it 'passes the expected params when no filters are provided' do
        # Arrange
        stub = stub_request(:get, "#{gp_fake_url}/fr/default/export-translations").with(query: { format: 'strings' }).to_return(body: 'content')
        dest = StringIO.new
        # Act
        described_class.download_glotpress_export_file(project_url: gp_fake_url, locale: 'fr', filters: nil, destination: dest)
        # Assert
        expect(stub).to have_been_made.once
        expect(dest.string).to eq('content')
      end

      it 'passes the expected params when a list of filters is provided' do
        # Arrange
        stub = stub_request(:get, "#{gp_fake_url}/fr/default/export-translations")
               .with(query: { format: 'strings', 'filters[status]': 'current', 'filters[term]': 'foobar' }).to_return(body: 'content')
        dest = StringIO.new
        # Act
        described_class.download_glotpress_export_file(project_url: gp_fake_url, locale: 'fr', filters: { status: 'current', term: 'foobar' }, destination: dest)
        # Assert
        expect(stub).to have_been_made.once
        expect(dest.string).to eq('content')
      end
    end

    describe 'destination parameter' do
      # it 'accepts an IO (File)' # Not really needed, as all previous tests already cover this by using a `StringIO`

      it 'accepts a String (path)' do
        Dir.mktmpdir('a8c-release-toolkit-tests-') do |tmp_dir|
          # Arrange
          # Note: in practice it seems that GlotPress's `.strings` exports are using UTF-8 (but served as `application/octet-stream`)
          #       but it does not hurt to ensure the download to a file can work with UTF-16 (and copy the binary stream verbatim)
          body = File.read(fixture('Localizable-utf16.strings'))
          stub = stub_request(:get, "#{gp_fake_url}/fr/default/export-translations").with(query: { format: 'strings' }).to_return(body: body)
          dest = File.join(tmp_dir, 'export.strings')
          # Act
          described_class.download_glotpress_export_file(project_url: gp_fake_url, locale: 'fr', filters: nil, destination: dest)
          # Assert
          expect(stub).to have_been_made.once
          expect(File).to exist(dest)
          expect(File.read(dest)).to eq(body)
        end
      end
    end

    describe 'invalid parameters' do
      it 'prints an `UI.error` if passed a non-existing locale (or any other 404)' do
        # Arrange
        stub = stub_request(:get, "#{gp_fake_url}/invalid/default/export-translations").with(query: { format: 'strings' }).to_return(status: [404, 'Not Found'])
        error_messages = []
        allow(FastlaneCore::UI).to receive(:error) { |message| error_messages.append(message) }
        dest = StringIO.new
        # Act
        described_class.download_glotpress_export_file(project_url: gp_fake_url, locale: 'invalid', filters: nil, destination: dest)
        # Assert
        expect(stub).to have_been_made.once
        expect(error_messages).to eq(['Error downloading locale `invalid` — 404 Not Found'])
      end

      it 'prints an `UI.error` if the destination cannot be written to' do
        # Arrange
        stub = stub_request(:get, "#{gp_fake_url}/fr/default/export-translations").with(query: { format: 'strings' }).to_return(body: 'content')
        error_messages = []
        allow(FastlaneCore::UI).to receive(:error) { |message| error_messages.append(message) }
        dest = '/these/are/not/the/droids/you/are/looking/for.strings'
        # Act
        described_class.download_glotpress_export_file(project_url: gp_fake_url, locale: 'fr', filters: nil, destination: dest)
        # Assert
        expect(stub).to have_been_made.once
        expect(File).not_to exist(dest)
        expect(error_messages).to eq(["Error downloading locale `fr` — No such file or directory @ rb_sysopen - #{dest}"])
      end
    end
  end
end
