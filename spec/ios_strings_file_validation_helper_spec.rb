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

  context 'when there are unquoted keys' do
    it 'returns an error' do
      # Unquoted strings are currently not supported by our validation helper in its current state, despite being a valid syntax, because we considered
      # that it was not worth adding complexity to our state machine logic for this use case — we expect all the `.strings` files we plan to validate will
      # come from GlotPress exports, and will thus always have their keys quoted.
      # If support for unquoted strings is added to our validation helper in the future, feel free to update this test example accordingly.
      expect { described_class.find_duplicated_keys(file: File.join(test_data_dir, 'ios_l10n_helper', 'expected-merged.strings')) }
        .to raise_error(RuntimeError, 'Invalid character `I` found on line 21, col 1')
    end
  end
end
