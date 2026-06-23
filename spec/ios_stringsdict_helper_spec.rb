# frozen_string_literal: true

require_relative 'spec_helper'

describe Fastlane::Helper::Ios::StringsdictHelper do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations', 'stringsdict') }

  def fixture(name)
    File.join(test_data_dir, name)
  end

  # Build a `.po` for the `simple.stringsdict` template (single context
  # "%d items") with the given translated forms.
  def simple_po(forms:, nplurals: forms.size, plural: '0')
    msgstrs = forms.each_with_index.map { |form, i| %(msgstr[#{i}] "#{form}") }.join("\n")
    <<~PO
      msgid ""
      msgstr ""
      "MIME-Version: 1.0\\n"
      "Content-Type: text/plain; charset=UTF-8\\n"
      "Plural-Forms: nplurals=#{nplurals}; plural=#{plural};\\n"

      msgctxt "%d items"
      msgid "%d item"
      msgid_plural "%d items"
      #{msgstrs}
    PO
  end

  # Run the reverse conversion against the given template, returning the parsed
  # output stringsdict and the list of missing contexts.
  def convert_po_to_stringsdict(po_content, template:, locale:)
    in_tmp_dir do |dir|
      po_path = File.join(dir, 'translations.po')
      out_path = File.join(dir, 'out.stringsdict')
      File.write(po_path, po_content)
      missing = described_class.generate_stringsdict_from_po(
        po_path: po_path, template_path: template, locale: locale, output_path: out_path
      )
      [described_class.read(path: out_path), missing]
    end
  end

  describe '.read' do
    it 'parses a stringsdict file into a Hash' do
      data = described_class.read(path: fixture('simple.stringsdict'))
      expect(data['%d items']['NSStringLocalizedFormatKey']).to eq('%#@count@')
      expect(data['%d items']['count']['one']).to eq('%d item')
      expect(data['%d items']['count']['other']).to eq('%d items')
    end

    it 'raises if the file is missing' do
      expect { described_class.read(path: 'does-not-exist.stringsdict') }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Stringsdict file not found/)
    end

    it 'raises a clear error when an entry is not a dictionary' do
      in_tmp_dir do |dir|
        bad = File.join(dir, 'bad.stringsdict')
        File.write(bad, <<~XML)
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0"><dict><key>oops</key><string>not a dictionary</string></dict></plist>
        XML
        expect { described_class.read(path: bad) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /entry 'oops' is not a dictionary/)
      end
    end
  end

  describe 'round-trip write/read' do
    it 'preserves the dictionary' do
      original = described_class.read(path: fixture('Localizable.stringsdict'))
      in_tmp_dir do |dir|
        out = File.join(dir, 'rt.stringsdict')
        described_class.write(data: original, path: out)
        expect(described_class.read(path: out)).to eq(original)
      end
    end
  end

  describe '.generate_pot' do
    it 'generates a plural .pot entry per variable, sorted by context' do
      in_tmp_dir do |dir|
        pot = File.join(dir, 'out.pot')
        count = described_class.generate_pot(stringsdict_paths: fixture('Localizable.stringsdict'), output_path: pot)
        content = File.read(pot)

        expect(count).to eq(3)
        # Single-variable entry uses the bare key as msgctxt.
        expect(content).to include(<<~ENTRY.chomp)
          msgctxt "%d files selected"
          msgid "%d file selected"
          msgid_plural "%d files selected"
          msgstr[0] ""
          msgstr[1] ""
        ENTRY
        # Multi-variable entries disambiguate with the variable name.
        expect(content).to include('msgctxt "photos_and_albums:albums"')
        expect(content).to include('msgctxt "photos_and_albums:photos"')
        # Entries are sorted by msgctxt ("%…" sorts before "p…").
        expect(content.index('msgctxt "%d files selected"')).to be < content.index('msgctxt "photos_and_albums:albums"')
        # Header advertises the (English source) plural form.
        expect(content).to include('Plural-Forms: nplurals=2; plural=n != 1;')
      end
    end

    it 'merges multiple stringsdict files into one .pot' do
      in_tmp_dir do |dir|
        pot = File.join(dir, 'merged.pot')
        count = described_class.generate_pot(
          stringsdict_paths: [fixture('simple.stringsdict'), fixture('Localizable.stringsdict')],
          output_path: pot
        )
        expect(count).to eq(4)
        expect(File.read(pot)).to include('msgctxt "%d items"')
      end
    end

    it 'raises on a key collision across files' do
      in_tmp_dir do |dir|
        pot = File.join(dir, 'dup.pot')
        expect do
          described_class.generate_pot(
            stringsdict_paths: [fixture('simple.stringsdict'), fixture('simple.stringsdict')],
            output_path: pot
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError, /Duplicate translation context/)
      end
    end

    it 'raises when a source entry is missing a required plural form' do
      in_tmp_dir do |dir|
        bad = File.join(dir, 'bad.stringsdict')
        described_class.write(
          data: {
            'broken' => {
              'NSStringLocalizedFormatKey' => '%#@count@',
              'count' => { 'NSStringFormatSpecTypeKey' => 'NSStringPluralRuleType', 'one' => 'just one' }
            }
          },
          path: bad
        )
        expect { described_class.generate_pot(stringsdict_paths: bad, output_path: File.join(dir, 'o.pot')) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /missing a required plural form/)
      end
    end

    it 'warns and drops source plural forms other than one/other (e.g. a `zero` override)' do
      in_tmp_dir do |dir|
        src = File.join(dir, 'zero.stringsdict')
        described_class.write(
          data: {
            'homes' => {
              'NSStringLocalizedFormatKey' => '%#@count@',
              'count' => {
                'NSStringFormatSpecTypeKey' => 'NSStringPluralRuleType',
                # iOS honors an English `zero` override (Apple: returns "No homes found" for 0),
                # but gettext has no slot for it — so it must be dropped *loudly*.
                'zero' => 'No homes found',
                'one' => '%d home found',
                'other' => '%d homes found'
              }
            }
          },
          path: src
        )
        pot = File.join(dir, 'out.pot')

        expect(FastlaneCore::UI).to receive(:important) do |message|
          expect(message).to include('zero')
          expect(message).to match(/drop/i)
        end

        described_class.generate_pot(stringsdict_paths: src, output_path: pot)

        content = File.read(pot)
        # `one`/`other` still convert…
        expect(content).to include('msgid "%d home found"')
        expect(content).to include('msgid_plural "%d homes found"')
        # …but the `zero` literal override is dropped.
        expect(content).not_to include('No homes found')
      end
    end

    it 'treats an empty `one` as absent — uses `other` as the singular rather than dropping the entry' do
      in_tmp_dir do |dir|
        src = File.join(dir, 'empty-one.stringsdict')
        described_class.write(
          data: {
            'k' => {
              'NSStringLocalizedFormatKey' => '%#@c@',
              'c' => { 'NSStringFormatSpecTypeKey' => 'NSStringPluralRuleType', 'one' => '', 'other' => '%d items' }
            }
          },
          path: src
        )
        pot = File.join(dir, 'out.pot')
        count = described_class.generate_pot(stringsdict_paths: src, output_path: pot)
        expect(count).to eq(1) # entry is emitted, not silently dropped via an empty msgid
        expect(File.read(pot)).to include('msgid "%d items"') # `other` becomes the msgid
      end
    end

    it 'raises when `other` is empty (an empty form counts as missing)' do
      in_tmp_dir do |dir|
        src = File.join(dir, 'empty-other.stringsdict')
        described_class.write(
          data: {
            'k' => {
              'NSStringLocalizedFormatKey' => '%#@c@',
              'c' => { 'NSStringFormatSpecTypeKey' => 'NSStringPluralRuleType', 'one' => '%d item', 'other' => '' }
            }
          },
          path: src
        )
        expect { described_class.generate_pot(stringsdict_paths: src, output_path: File.join(dir, 'o.pot')) }
          .to raise_error(FastlaneCore::Interface::FastlaneError, /missing a required plural form/)
      end
    end
  end

  describe '.generate_stringsdict_from_po' do
    let(:simple) { fixture('simple.stringsdict') }

    it 'maps a 2-form locale to one/other' do
      data, missing = convert_po_to_stringsdict(
        simple_po(forms: ['1 elemento', '%d elementos'], plural: 'n != 1'),
        template: simple, locale: 'es'
      )
      expect(missing).to be_empty
      expect(data['%d items']['count']).to include('one' => '1 elemento', 'other' => '%d elementos')
      expect(data['%d items']['count']).not_to have_key('few')
    end

    it 'maps a single-form locale to other only' do
      data, = convert_po_to_stringsdict(simple_po(forms: ['%d 件']), template: simple, locale: 'ja')
      expect(data['%d items']['count'].slice('zero', 'one', 'two', 'few', 'many', 'other'))
        .to eq('other' => '%d 件')
    end

    it 'maps an East-Slavic 3-form locale and back-fills the mandatory `other`' do
      data, = convert_po_to_stringsdict(
        simple_po(forms: %w[ru-one ru-few ru-many], nplurals: 3),
        template: simple, locale: 'ru'
      )
      expect(data['%d items']['count'].slice('one', 'few', 'many', 'other')).to eq(
        'one' => 'ru-one', 'few' => 'ru-few', 'many' => 'ru-many', 'other' => 'ru-many'
      )
    end

    it 'maps Arabic across all six categories' do
      data, = convert_po_to_stringsdict(
        simple_po(forms: %w[ar-zero ar-one ar-two ar-few ar-many ar-other], nplurals: 6),
        template: simple, locale: 'ar'
      )
      expect(data['%d items']['count'].slice('zero', 'one', 'two', 'few', 'many', 'other')).to eq(
        'zero' => 'ar-zero', 'one' => 'ar-one', 'two' => 'ar-two',
        'few' => 'ar-few', 'many' => 'ar-many', 'other' => 'ar-other'
      )
    end

    it 'preserves the format key, spec type and value type from the template' do
      data, = convert_po_to_stringsdict(simple_po(forms: %w[a b], plural: 'n != 1'), template: simple, locale: 'en')
      entry = data['%d items']
      expect(entry['NSStringLocalizedFormatKey']).to eq('%#@count@')
      expect(entry['count']['NSStringFormatSpecTypeKey']).to eq('NSStringPluralRuleType')
      expect(entry['count']['NSStringFormatValueTypeKey']).to eq('d')
    end

    it 'round-trips a multi-variable entry' do
      po = <<~PO
        msgid ""
        msgstr ""
        "Plural-Forms: nplurals=2; plural=n != 1;\\n"

        msgctxt "%d files selected"
        msgid "%d file selected"
        msgid_plural "%d files selected"
        msgstr[0] "1 archivo"
        msgstr[1] "%d archivos"

        msgctxt "photos_and_albums:photos"
        msgid "%d photo"
        msgid_plural "%d photos"
        msgstr[0] "1 foto"
        msgstr[1] "%d fotos"

        msgctxt "photos_and_albums:albums"
        msgid "%d album"
        msgid_plural "%d albums"
        msgstr[0] "1 álbum"
        msgstr[1] "%d álbumes"
      PO
      data, missing = convert_po_to_stringsdict(po, template: fixture('Localizable.stringsdict'), locale: 'es')
      expect(missing).to be_empty
      expect(data['photos_and_albums']['NSStringLocalizedFormatKey']).to eq('%#@photos@ in %#@albums@')
      expect(data['photos_and_albums']['photos']).to include('one' => '1 foto', 'other' => '%d fotos')
      expect(data['photos_and_albums']['albums']).to include('one' => '1 álbum', 'other' => '%d álbumes')
    end

    it 'falls back to English and reports contexts with no translation' do
      data, missing = convert_po_to_stringsdict(simple_po(forms: ['', '']), template: simple, locale: 'en')
      expect(missing).to eq(['%d items'])
      # Output stays valid by reusing the English source forms.
      expect(data['%d items']['count']).to include('one' => '%d item', 'other' => '%d items')
    end

    it 'warns when a locale entry is only partially translated' do
      expect(FastlaneCore::UI).to receive(:important) do |message|
        expect(message).to include('many')
        expect(message).to match(/incomplete|untranslated/i)
      end
      # `ru` needs one/few/many; the translator left `many` blank.
      data, missing = convert_po_to_stringsdict(
        simple_po(forms: ['ru-one', 'ru-few', ''], nplurals: 3),
        template: simple, locale: 'ru'
      )
      # Not reported as fully-missing — it does have *some* translation…
      expect(missing).to be_empty
      # …but the untranslated `many` is absent (falls back), not silently wrong-but-present.
      expect(data['%d items']['count']).not_to have_key('many')
      expect(data['%d items']['count']).to include('one' => 'ru-one', 'few' => 'ru-few', 'other' => 'ru-few')
    end

    it 'maps Hebrew to one/other — GlotPress is 2-form, so the CLDR dual is not represented' do
      data, missing = convert_po_to_stringsdict(
        simple_po(forms: ['פריט אחד', '%d פריטים'], plural: 'n != 1'),
        template: simple, locale: 'he'
      )
      expect(missing).to be_empty
      # Accepted limitation: no `two` category — iOS falls back to `other` for n=2.
      expect(data['%d items']['count'].slice('one', 'two', 'other'))
        .to eq('one' => 'פריט אחד', 'other' => '%d פריטים')
    end

    it 'raises for an unmapped locale' do
      expect do
        convert_po_to_stringsdict(simple_po(forms: ['x']), template: simple, locale: 'xx')
      end.to raise_error(Fastlane::Helper::Ios::PluralRules::UnknownLocaleError)
    end

    it 'fails loud for Welsh, whose GlotPress rule is incompatible with CLDR categories' do
      expect do
        convert_po_to_stringsdict(simple_po(forms: %w[a b c d], nplurals: 4), template: simple, locale: 'cy')
      end.to raise_error(Fastlane::Helper::Ios::PluralRules::UnknownLocaleError, /Welsh/)
    end

    it 'fails loud when the .po declares a different plural-form count than the table expects' do
      # `ru` maps to 3 categories; a .po declaring nplurals=2 means GlotPress's
      # plural rule has drifted from the table — the signal to regenerate it.
      expect do
        convert_po_to_stringsdict(simple_po(forms: %w[a b], nplurals: 2), template: simple, locale: 'ru')
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /declares nplurals=2.*3 categor/m)
    end

    it 'reads nplurals from the header, not a stray `nplurals=` elsewhere in the .po' do
      po = <<~PO
        # A misleading comment that mentions nplurals=4 must not be picked up.
        msgid ""
        msgstr ""
        "Plural-Forms: nplurals=3; plural=(n != 1);\\n"

        msgctxt "%d items"
        msgid "%d item"
        msgid_plural "%d items"
        msgstr[0] "ru-one"
        msgstr[1] "ru-few"
        msgstr[2] "ru-many"
      PO
      data, missing = convert_po_to_stringsdict(po, template: simple, locale: 'ru')
      expect(missing).to be_empty
      expect(data['%d items']['count'].slice('one', 'few', 'many')).to eq(
        'one' => 'ru-one', 'few' => 'ru-few', 'many' => 'ru-many'
      )
    end
  end
end
