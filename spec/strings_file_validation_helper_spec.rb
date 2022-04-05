require 'spec_helper'

describe Fastlane::Helper::StringsFileValidationHelper do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations') }

  context 'when there is an escape character in the root context' do
    it 'raises' do
      input = File.join(test_data_dir, 'strings-with-escape-character-in-root-context.strings')
      expect { described_class.find_duplicated_keys(file: input) }
        .to raise_error(RuntimeError, 'Found escaped character outside of allowed contexts (current context: root)')
    end
  end

  context 'when there are duplicated keys' do
    it 'returns them in an array' do
      input = File.join(test_data_dir, 'file-with-duplicated-keys.strings')

      expect(described_class.find_duplicated_keys(file: input)).to match_array [
        { key: 'dup1', lines: [30, 31] },
        { key: 'dup2', lines: [33, 35] },
        { key: 'dup3', lines: [36, 39] },
        { key: 'dup4', lines: [41, 42] },
        { key: '\U0025 key', lines: [49, 50] },
        { key: '\U0026 key', lines: [52, 54] },
        { key: 'key with \"%@\" character', lines: [60, 61] },
        { key: 'key with \"%@\" but diff translations', lines: [63, 64] },
        { key: 'key with multiple \"%@\" escapes \":)\" in it', lines: [66, 68] },
        { key: 'Login to a \"%@\" account', lines: [67, 69] },
        { key: 'key with trailing spaces ', lines: [76, 77] },
        { key: 'key with \"%@\" and = character', lines: [71, 72] },
        { key: 'key with \"%@\" character and equal in translation', lines: [73, 74] },
        { key: 'key repeated more than twice', lines: [79, 80, 81] },
      ]
    end
  end

  context 'when there are no duplicated keys' do
    it 'returns an empty array' do
      # Piggy back on some of the `.strings` from other tests to ensure this
      # behaves correctly
      expect(
        described_class.find_duplicated_keys(
          file: File.join(test_data_dir, 'ios_l10n_helper', 'expected-merged.strings')
        )
      ).to be_empty
      expect(
        described_class.find_duplicated_keys(
          file: File.join(test_data_dir, 'ios_extract_keys_from_strings_files', 'Resources', 'en.lproj', 'Localizable.strings')
        )
      ).to be_empty
    end
  end
end
