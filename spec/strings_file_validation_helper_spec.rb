require 'spec_helper'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?('UI')

  module Helper
    class StringsFileValidationHelper
      # Inspects the given `.strings` file for duplicated keys.
      #
      # @param [String] file The path to the file to inspect.
      def self.find_duplicated_keys(file:)
        found_keys = {}
        duplicated_keys = []
        File.read(file).lines.each_with_index do |line, index|
          key = extract_key(line: line)

          next if key.nil?

          # Check if that key was already encountered in the past
          existing = found_keys[key]

          duplicated_keys.append(key) unless existing.nil?
          # TODO: Use proper Fastlane UI methods for this, or better rely on
          # the consumer to read the return Hash (itself a TODO) and print an
          # error. This is an helper, after all.
          puts "warning: key `#{key}` on line #{index + 1} is a duplicate of a similar key found on line #{existing + 1}" unless existing.nil?

          # Memorize the line at which this key appeared in the source `.strings`
          # file
          found_keys[key] = index
        end

        duplicated_keys
      end

      def self.extract_key(line:)
        regexp = /\s*"([^"]+.*)"\s*=/
        key_range = line.match(regexp)&.offset(1)

        return nil if key_range.nil?

        line[key_range[0]...key_range[1]]
      end
    end
  end
end

describe Fastlane::Helper::StringsFileValidationHelper do
  let(:test_data_dir) { File.join(File.dirname(__FILE__), 'test-data', 'translations') }

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
