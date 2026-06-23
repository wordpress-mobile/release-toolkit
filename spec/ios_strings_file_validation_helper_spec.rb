# frozen_string_literal: true

require 'spec_helper'

describe Fastlane::Helper::Ios::StringsFileValidationHelper do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations') }

  context 'when there is an escape character in the root context' do
    it 'raises' do
      input = File.join(test_data_dir, 'strings-with-escape-character-in-root-context.strings')
      expect { described_class.find_duplicated_keys(file: input) }
        .to raise_error(RuntimeError, 'Found escaped character outside of allowed contexts on line 8 (current context: root)')
    end
  end

  context 'when there are duplicated keys' do
    it 'returns them in an array' do
      input = File.join(test_data_dir, 'file-with-duplicated-keys.strings')

      expect(described_class.find_duplicated_keys(file: input)).to eq(
        {
          'dup1' => [30, 31],
          'dup2' => [33, 35],
          'dup3' => [36, 39],
          'dup4' => [41, 42],
          '\U0025 key' => [49, 50],
          '\U0026 key' => [52, 54],
          'key with \"%@\" character' => [60, 61],
          'key with \"%@\" but diff translations' => [63, 64],
          'key with multiple \"%@\" escapes \":)\" in it' => [66, 68],
          'Login to a \"%@\" account' => [67, 69],
          'key with trailing spaces ' => [76, 77],
          'key with \"%@\" and = character' => [71, 72],
          'key with \"%@\" character and equal in translation' => [73, 74],
          'key repeated more than twice' => [79, 80, 81]
        }
      )
    end
  end

  context 'when there are no duplicated keys' do
    it 'returns an empty array' do
      # Piggy back on some of the `.strings` from other tests to ensure this behaves correctly
      expect(
        described_class.find_duplicated_keys(
          file: File.join(test_data_dir, 'ios_l10n_helper', 'expected-merged-prefixed.strings')
        )
      ).to be_empty
      expect(
        described_class.find_duplicated_keys(
          file: File.join(test_data_dir, 'ios_extract_keys_from_strings_files', 'Resources', 'en.lproj', 'Localizable.strings')
        )
      ).to be_empty
    end
  end

  context 'when there are unquoted keys and values' do
    # Unquoted strings — keys and values — are valid `.strings` syntax (the old-style ASCII plist format)
    # and are common in `InfoPlist.strings` (e.g. `CFBundleDisplayName = WordPress;`).
    it 'parses them alongside quoted keys without raising, finding no duplicates among unique keys' do
      # `expected-merged.strings` mixes quoted (`key1`–`key3`) and unquoted (`InfoKey1`–`InfoKey3`) keys.
      expect(described_class.find_duplicated_keys(file: File.join(test_data_dir, 'ios_l10n_helper', 'expected-merged.strings'))).to be_empty
    end

    it 'detects duplicates among unquoted keys, reporting each occurrence line' do
      content = <<~STRINGS
        CFBundleName = "WordPress";
        NSCameraUsageDescription = "Take photos";
        CFBundleName = "Jetpack";
      STRINGS
      with_tmp_file(named: 'InfoPlist.strings', content: content) do |path|
        expect(described_class.find_duplicated_keys(file: path)).to eq('CFBundleName' => [1, 3])
      end
    end

    it 'parses unquoted *values* (not just keys) without raising, and finds duplicates among them' do
      # `CFBundleName = WordPress;` (both key and value unquoted) is valid ASCII-plist that `plutil`
      # parses; the scanner must tokenize it rather than choking on the unquoted value.
      content = <<~STRINGS
        CFBundleName = WordPress;
        CFBundleShortVersionString = 1.0;
        CFBundleName = Jetpack;
      STRINGS
      with_tmp_file(named: 'InfoPlist.strings', content: content) do |path|
        expect(described_class.find_duplicated_keys(file: path)).to eq('CFBundleName' => [1, 3])
      end
    end

    it 'parses unquoted keys containing `.`, `-`, `_`, `$`, `:`, and `/` (the chars `plutil` allows)' do
      content = <<~STRINGS
        com.example.app-name_2 = "v";
        a$b:c/d = "v";
        a$b:c/d = "w";
      STRINGS
      with_tmp_file(named: 'InfoPlist.strings', content: content) do |path|
        expect(described_class.find_duplicated_keys(file: path)).to eq('a$b:c/d' => [2, 3])
      end
    end
  end

  context 'when comments appear between the tokens of a statement' do
    # Comments are valid `.strings` syntax not only on their own line but also *between* the tokens of a
    # statement — after a key, around the `=`, or before the terminating `;`. `plutil` accepts all of these,
    # so the scanner must tokenize them rather than raising `Invalid character` on the `/`.
    it 'parses comments after a key, around the `=`, and before the `;` without raising' do
      content = <<~STRINGS
        "afterKey" /* note */ = "1";
        "aroundEq" = /* note */ "2";
        "beforeSemicolon" = "3" /* note */;
        unquotedKey /* note */ = unquotedValue;
      STRINGS
      with_tmp_file(named: 'Localizable.strings', content: content) do |path|
        expect(described_class.find_duplicated_keys(file: path)).to be_empty
      end
    end

    it 'still detects duplicate keys in a file that also contains inline comments' do
      content = <<~STRINGS
        "dup" /* first */ = "1";
        "unique" = "x";
        "dup" = "2" /* second */;
      STRINGS
      with_tmp_file(named: 'Localizable.strings', content: content) do |path|
        expect(described_class.find_duplicated_keys(file: path)).to eq('dup' => [1, 3])
      end
    end

    it 'does not mistake a `/`-leading unquoted value for the start of a comment' do
      # A `/` right after `=` may begin a comment OR an unquoted value (e.g. a path or URL); the latter,
      # which `plutil` accepts, must still parse rather than be swallowed as a comment.
      content = <<~STRINGS
        "path" = /usr/bin/tool;
        "url" = https://example.com/x;
        "path" = /opt;
      STRINGS
      with_tmp_file(named: 'Localizable.strings', content: content) do |path|
        expect(described_class.find_duplicated_keys(file: path)).to eq('path' => [1, 3])
      end
    end
  end

  describe '.scan_for_duplicate_keys' do
    it 'returns `[:scanned, duplicates]` for a `:text` file, with the duplicate hash (empty if none)' do
      with_tmp_file(named: 'dups.strings', content: "\"k\" = \"a\";\n\"k\" = \"b\";\n") do |path|
        expect(described_class.scan_for_duplicate_keys(file: path)).to eq([:scanned, { 'k' => [1, 2] }])
      end
      with_tmp_file(named: 'unique.strings', content: "\"k\" = \"a\";\n\"j\" = \"b\";\n") do |path|
        expect(described_class.scan_for_duplicate_keys(file: path)).to eq([:scanned, {}])
      end
    end

    it 'returns `[:unsupported_format, format]` for a non-`:text` (XML) plist, without scanning' do
      in_tmp_dir do |dir|
        path = File.join(dir, 'x.strings')
        Fastlane::Helper::Ios::L10nHelper.generate_strings_file_from_hash(translations: { 'a' => 'b' }, output_path: path)
        status, format = described_class.scan_for_duplicate_keys(file: path)
        expect(status).to eq(:unsupported_format)
        expect(format).to eq(:xml)
      end
    end

    it 'returns `[:unscannable, message]` for a `:text` plist the tokenizer cannot read' do
      with_tmp_file(named: 'nested.strings', content: "\"k\" = { a = b; };\n") do |path|
        status, message = described_class.scan_for_duplicate_keys(file: path)
        expect(status).to eq(:unscannable)
        expect(message).to match(/Invalid character/)
      end
    end
  end
end
