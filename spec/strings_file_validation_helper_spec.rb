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
    it 'returns them' do
      input = File.join(test_data_dir, 'file-with-duplicated-keys.strings')

      # TODO: This should become a hash with key and an array of the line
      # numbers where they occur.
      expect(described_class.find_duplicated_keys(file: input)).to match_array [
        'dup1', 'dup2', 'dup3', 'dup4',
        '\U0025 key', '\U0026 key',
        'key with \"%@\" character',
        'key with \"%@\" but diff translations',
        'key with multiple \"%@\" escapes \":)\" in it',
        'key with trailing spaces ',
        'key with \"%@\" and = character',
        'key with \"%@\" character and equal in translation',
        'Login to a \"%@\" account',
      ]
    end
  end
end
