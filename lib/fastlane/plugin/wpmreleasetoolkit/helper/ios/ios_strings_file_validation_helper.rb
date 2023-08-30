module Fastlane
  module Helper
    module Ios
      class StringsFileValidationHelper
        # context can be one of:
        #   :root, :maybe_comment_start, :in_line_comment, :in_block_comment,
        #   :maybe_block_comment_end, :in_quoted_key,
        #   :after_quoted_key_before_eq, :after_quoted_key_and_equal,
        #   :in_quoted_value, :after_quoted_value
        State = Struct.new(:context, :buffer, :in_escaped_ctx, :found_key, keyword_init: true)

        TRANSITIONS = {
          root: {
            /\s/u => :root,
            '/' => :maybe_comment_start,
            '"' => :in_quoted_key
          },
          maybe_comment_start: {
            '/' => :in_line_comment,
            /\*/u => :in_block_comment
          },
          in_line_comment: {
            "\n" => :root,
            /./u => :in_line_comment
          },
          in_block_comment: {
            /\*/ => :maybe_block_comment_end,
            /./mu => :in_block_comment
          },
          maybe_block_comment_end: {
            '/' => :root,
            /./mu => :in_block_comment
          },
          in_quoted_key: {
            '"' => lambda do |state, _|
              state.found_key = state.buffer.string.dup
              state.buffer.string = ''
              :after_quoted_key_before_eq
            end,
            /./u => lambda do |state, c|
              state.buffer.write(c)
              :in_quoted_key
            end
          },
          after_quoted_key_before_eq: {
            /\s/u => :after_quoted_key_before_eq,
            '=' => :after_quoted_key_and_eq
          },
          after_quoted_key_and_eq: {
            /\s/u => :after_quoted_key_and_eq,
            '"' => :in_quoted_value
          },
          in_quoted_value: {
            '"' => :after_quoted_value,
            /./mu => :in_quoted_value
          },
          after_quoted_value: {
            /\s/u => :after_quoted_value,
            ';' => :root
          }
        }.freeze

        # Inspects the given `.strings` file for duplicated keys, returning them if any.
        #
        # @param [String] file The path to the file to inspect.
        # @return [Hash<String, Array<Int>] Hash with the dublipcated keys.
        #         Each element has the duplicated key (from the `.strings`) as key and an array of line numbers where the key occurs as value.
        def self.find_duplicated_keys(file:)
          keys_with_lines = Hash.new([])

          state = State.new(context: :root, buffer: StringIO.new, in_escaped_ctx: false, found_key: nil)

          # Using our `each_utf8_line` helper instead of `File.readlines` ensures we can also read files that are
          # encoded in UTF-16, yet process each of their lines as a UTF-8 string, so that `RegExp#match?` don't throw
          # an `Encoding::CompatibilityError` exception. (Note how all our `RegExp`s in `TRANSITIONS` have the `u` flag)
          Fastlane::Helper::Ios::L10nHelper.read_utf8_lines(file).each_with_index do |line, line_no|
            line.chars.each_with_index do |c, col_no|
              # Handle escaped characters at a global level.
              # This is more straightforward than having to account for it in the `TRANSITIONS` table.
              if state.in_escaped_ctx || c == '\\'
                # Just because we check for escaped characters at the global level, it doesn't mean we allow them in every context.
                allowed_contexts_for_escaped_characters = %i[in_quoted_key in_quoted_value in_block_comment in_line_comment]
                raise "Found escaped character outside of allowed contexts on line #{line_no + 1} (current context: #{state.context})" unless allowed_contexts_for_escaped_characters.include?(state.context)

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

              keys_with_lines[key] += [line_no + 1]
            end
          end

          keys_with_lines.keep_if { |_, lines| lines.count > 1 }
        end
      end
    end
  end
end
