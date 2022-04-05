module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?('UI')

  module Helper
    class StringsFileValidationHelper
      # context can be one of:
      #   :root, :maybe_comment_start, :in_line_comment, :in_block_comment,
      #   :maybe_block_comment_end, :in_quoted_key,
      #   :after_quoted_key_before_eq, :after_quoted_key_and_equal,
      #   :in_quoted_value, :after_quoted_value
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

        state = State.new(context: :root, buffer: StringIO.new, in_escaped_ctx: false, found_key: nil)

        File.readlines(file).each_with_index do |line, line_no|
          line.chars.each_with_index do |c, col_no|
            # Handle escaped characters at a global level. This is more
            # straightforward than having a `TRANSITIONS` table that account
            # for it.
            if state.in_escaped_ctx || c == '\\'
              # Just because we check for escaped characters at the global
              # level, it doesn't mean we allow them in every context.
              raise "Found escaped character outside of allowed contexts (current context: #{state.context})" unless [:in_quoted_key, :in_quoted_value, :in_block_comment].include?(state.context)

              state.buffer.write(c) if state.context == :in_quoted_key
              state.in_escaped_ctx = !state.in_escaped_ctx
              next
            end

            # Look at the transitions table for the current context, and find
            # the first transition matching the current character
            (_, next_context) = TRANSITIONS[state.context].find { |regex, _| c.match?(regex) } || [nil, nil]
            raise "Invalid character `#{c}` found on line #{line_no + 1}, col #{col_no + 1}" if next_context.nil?

            state.context = next_context.is_a?(Proc) ? next_context.call(state, c) : next_context
            next unless state.found_key

            # If we just exited the :in_quoted_key context and thus have found
            # a new key, process it
            key = state.found_key.dup
            state.found_key = nil

            all_keys[key] = all_keys[key].nil? ? [line_no + 1] : all_keys[key].push(line_no + 1)
          end
        end
        all_keys.select { |_, lines| lines.length > 1 }.map { |key, lines| { key: key, lines: lines } }
      end
    end
  end
end
