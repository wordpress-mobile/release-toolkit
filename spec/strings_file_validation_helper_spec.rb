require 'spec_helper'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?('UI')

  module Helper
    class StringsFileValidationHelper
      # context can be one of:
      #   :root, :maybe_comment_start, :in_line_comment, :in_block_comment, :maybe_block_comment_end,
      #   :in_quoted_key, :after_quoted_key_before_eq, :after_quoted_key_and_equal, :in_quoted_value, :after_quoted_value
      State = Struct.new(:context, :buffer, :in_escaped_ctx, :found_key, keyword_init: true)

      TRANSITIONS = {
        root: {
          /\s/ => :root,
          '/' => :maybe_comment_start,
          '"' => :in_quoted_key
        },
        maybe_comment_start: {
          '/' => :in_line_comment,
          /\*/ => :in_block_comment
        },
        in_line_comment: {
          "\n" => :root,
          /./ => :in_line_comment
        },
        in_block_comment: {
          /\*/ => :maybe_block_comment_end,
          /./m => :in_block_comment
        },
        maybe_block_comment_end: {
          '/' => :root,
          /./m => :in_block_comment
        },
        in_quoted_key: {
          '"' => lambda do |state, _|
            state.found_key = state.buffer.string.dup
            state.buffer.string = ''
            :after_quoted_key_before_eq
          end,
          /./ => lambda do |state, c|
            state.buffer.write(c)
            :in_quoted_key
          end
        },
        after_quoted_key_before_eq: {
          /\s/ => :after_quoted_key_before_eq,
          '=' => :after_quoted_key_and_eq
        },
        after_quoted_key_and_eq: {
          /\s/ => :after_quoted_key_and_eq,
          '"' => :in_quoted_value
        },
        in_quoted_value: {
          '"' => :after_quoted_value,
          /./m => :in_quoted_value
        },
        after_quoted_value: {
          /\s/ => :after_quoted_value,
          ';' => :root
        }
      }.freeze

      # Inspects the given `.strings` file for duplicated keys.
      #
      # @param [String] file The path to the file to inspect.
      def self.find_duplicated_keys(file:)
        all_keys = {}
        dup_keys = []

        state = State.new(context: :root, buffer: StringIO.new, in_escaped_ctx: false, found_key: nil)

        File.readlines(file).each_with_index do |line, line_no|
          line.chars.each_with_index do |c, col_no|
            # Handle escaped characters at a global level
            if (!state.in_escaped_ctx && c == '\\') || state.in_escaped_ctx
              state.buffer.write(c) if state.context == :in_quoted_key
              state.in_escaped_ctx = !state.in_escaped_ctx
              next
            end

            # Look at the transitions table for the current context, and find the first transition matching the current character
            (_, next_context) = TRANSITIONS[state.context].find { |regex, _| c.match?(regex) } || [nil, nil]
            raise "Invalid character `#{c}` found on line #{line_no + 1}, col #{col_no + 1}" if next_context.nil?

            state.context = next_context.is_a?(Proc) ? next_context.call(state, c) : next_context
            next unless state.found_key

            # If we just exited the :in_quoted_key context and thus have found a new key, process it
            key = state.found_key.dup
            state.found_key = nil
            if all_keys.key?(key)
              puts "warning: key `#{key}` on line #{line_no + 1} is a duplicate of a similar key found on line #{all_keys[key]}" # UI.warning
              dup_keys.append(key)
            else
              all_keys[key] = line_no + 1
            end
          end
        end
        dup_keys
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
