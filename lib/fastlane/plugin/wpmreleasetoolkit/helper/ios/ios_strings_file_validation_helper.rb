# frozen_string_literal: true

module Fastlane
  module Helper
    module Ios
      class StringsFileValidationHelper
        # context can be one of:
        #   :root, :maybe_comment_start, :maybe_comment_or_value, :in_line_comment, :in_block_comment,
        #   :maybe_block_comment_end, :in_quoted_key, :in_unquoted_key,
        #   :after_quoted_key_before_eq, :after_quoted_key_and_eq,
        #   :in_quoted_value, :in_unquoted_value, :after_quoted_value
        #
        # `resume_context` holds the context to return to once a comment ends. Comments are valid not only at
        # the top level but also *between* the tokens of a statement (e.g. `"key" /* note */ = "value";`), so a
        # comment must resume the state it interrupted rather than always dropping back to `:root`.
        # `depth` tracks how deeply nested we are inside a container value (`{ … }` / `( … )`); see `:in_container_value`.
        State = Struct.new(:context, :buffer, :in_escaped_ctx, :found_key, :resume_context, :depth)

        # Characters allowed in an *unquoted* string — a key or a value. Unquoted strings are valid
        # `.strings` syntax (the old-style ASCII property-list format) and are common in `InfoPlist.strings`
        # (e.g. `CFBundleName = WordPress;`). `plutil` accepts alphanumerics plus `_ . - $ : /` in an
        # unquoted string, so we match the same set: this scanner only ever runs on input `plutil` has
        # already accepted, and matching its grammar keeps a file it parses from tripping the scanner.
        # An unquoted key runs until the first whitespace or `=`; an unquoted value until whitespace or `;`.
        UNQUOTED_STRING_CHARACTER = %r{[a-zA-Z0-9_.$:/-]}u

        # Enter a comment from an inter-token position, remembering where to resume once it ends.
        # (`state.context` is still the originating state when a transition lambda runs — it's only reassigned
        # to the lambda's return value afterwards — so this captures the state the comment interrupts.)
        ENTER_COMMENT = lambda do |state, _c|
          state.resume_context = state.context
          :maybe_comment_start
        end

        # A `/` between `=` and the value is ambiguous: it can start a comment (`/* … */` or `// …`) or be the
        # first character of an unquoted value (e.g. a path like `/usr/bin`). Defer the decision by one character
        # via `:maybe_comment_or_value`.
        ENTER_COMMENT_OR_VALUE = lambda do |state, _c|
          state.resume_context = state.context
          :maybe_comment_or_value
        end

        # Restore the context a comment interrupted (defaults to `:root`), then clear the saved context.
        RESUME_AFTER_COMMENT = lambda do |state, _c|
          resume = state.resume_context || :root
          state.resume_context = :root
          resume
        end

        # A value can be a nested container — a dictionary `{ … }` or an array `( … )` — which `plutil` accepts
        # (e.g. `"k" = { a = b; };` or `"k" = ( "a", "b" );`). We don't rewrite or record anything *inside* a
        # container: its inner keys are not top-level keys, and `prefix_keys` copies the value through verbatim.
        # We only need to find the matching close delimiter, so we just count nesting depth. `OPEN_CONTAINER`
        # doubles as the entry transition from `:after_quoted_key_and_eq` and as the nested-open transition.
        OPEN_CONTAINER = lambda do |state, _c|
          state.depth += 1
          :in_container_value
        end

        # Close one level of nesting. The value is only finished — and we go back to expecting the terminating
        # `;` — once depth returns to 0; otherwise we're still inside an outer container.
        CLOSE_CONTAINER = lambda do |state, _c|
          state.depth -= 1
          state.depth.zero? ? :after_quoted_value : :in_container_value
        end

        # A `/` inside a container may start a comment — whose body can contain `{ } ( ) ; "` that must NOT count
        # toward nesting — or just be an ordinary value character (e.g. a path). Defer the decision one char,
        # resuming the container in either case.
        ENTER_CONTAINER_COMMENT = lambda do |state, _c|
          state.resume_context = :in_container_value
          :maybe_container_comment
        end

        TRANSITIONS = {
          root: {
            /\s/u => :root,
            '/' => :maybe_comment_start,
            '"' => :in_quoted_key,
            # An unquoted key, e.g. `CFBundleName = "…";` as used by `InfoPlist.strings`.
            UNQUOTED_STRING_CHARACTER => lambda do |state, c|
              state.buffer.write(c)
              :in_unquoted_key
            end
          },
          maybe_comment_start: {
            '/' => :in_line_comment,
            /\*/u => :in_block_comment
          },
          # Reached only from `:after_quoted_key_and_eq`, where a leading `/` might begin a comment or an
          # unquoted value. A `*` or `/` confirms a comment; anything else means the `/` was the value's first
          # character (values aren't buffered, so we just continue scanning the value).
          maybe_comment_or_value: {
            /\*/u => :in_block_comment,
            '/' => :in_line_comment,
            /./mu => lambda do |state, _c|
              state.resume_context = :root
              :in_unquoted_value
            end
          },
          in_line_comment: {
            "\n" => RESUME_AFTER_COMMENT,
            /./u => :in_line_comment
          },
          in_block_comment: {
            /\*/ => :maybe_block_comment_end,
            /./mu => :in_block_comment
          },
          maybe_block_comment_end: {
            '/' => RESUME_AFTER_COMMENT,
            /./mu => :in_block_comment
          },
          in_quoted_key: {
            '"' => lambda do |state, _|
              state.found_key = state.buffer.string.dup
              state.buffer = StringIO.new
              :after_quoted_key_before_eq
            end,
            /./u => lambda do |state, c|
              state.buffer.write(c)
              :in_quoted_key
            end
          },
          in_unquoted_key: {
            # The key ends at the first whitespace or `=`. Whitespace still expects an `=` next;
            # an `=` moves straight on to the value.
            /[\s=]/u => lambda do |state, c|
              state.found_key = state.buffer.string.dup
              state.buffer = StringIO.new
              c == '=' ? :after_quoted_key_and_eq : :after_quoted_key_before_eq
            end,
            UNQUOTED_STRING_CHARACTER => lambda do |state, c|
              state.buffer.write(c)
              :in_unquoted_key
            end
          },
          after_quoted_key_before_eq: {
            # A comment may sit between the key and the `=` (e.g. `"key" /* note */ = "value";`).
            '/' => ENTER_COMMENT,
            /\s/u => :after_quoted_key_before_eq,
            '=' => :after_quoted_key_and_eq
          },
          after_quoted_key_and_eq: {
            # A `/` here may start a comment or an unquoted value (which can contain `/`); disambiguate one char
            # later. This entry must precede `UNQUOTED_STRING_CHARACTER` below, which also matches `/`.
            '/' => ENTER_COMMENT_OR_VALUE,
            /\s/u => :after_quoted_key_and_eq,
            '"' => :in_quoted_value,
            # A container value — a dictionary `{ … }` or an array `( … )`, which may nest (e.g. `"k" = { a = b; };`).
            /[{(]/u => OPEN_CONTAINER,
            # An unquoted value, e.g. `CFBundleName = WordPress;` as used by `InfoPlist.strings`.
            UNQUOTED_STRING_CHARACTER => :in_unquoted_value
          },
          in_quoted_value: {
            '"' => :after_quoted_value,
            /./mu => :in_quoted_value
          },
          in_unquoted_value: {
            # The value ends at the first whitespace or the terminating `;`. Its contents are irrelevant
            # to duplicate-key detection, so — unlike a key — we don't buffer it.
            ';' => :root,
            /\s/u => :after_quoted_value,
            UNQUOTED_STRING_CHARACTER => :in_unquoted_value
          },
          after_quoted_value: {
            # A comment may sit between the value and the terminating `;` (e.g. `"key" = "value" /* note */;`).
            '/' => ENTER_COMMENT,
            /\s/u => :after_quoted_value,
            ';' => :root
          },
          # Inside a container value (`{ … }` / `( … )`). We ignore the contents — inner keys aren't top-level
          # keys and the value is copied verbatim by `prefix_keys` — and only track nesting so we can find the
          # matching close. Quoted strings and comments are entered explicitly because their bodies can contain
          # `{ } ( ) ;` that must not affect the depth count; everything else (`=`, `;`, `,`, whitespace, unquoted
          # text, newlines) is consumed by the catch-all, which must stay LAST so the specific keys win first.
          in_container_value: {
            /[{(]/u => OPEN_CONTAINER,
            /[})]/u => CLOSE_CONTAINER,
            '"' => :in_container_quoted_string,
            '/' => ENTER_CONTAINER_COMMENT,
            /./mu => :in_container_value
          },
          # A quoted string inside a container. Skipped wholesale (its `{ } ( ) ; ,` are literal, not structural)
          # until the closing quote returns us to the container. Escapes are handled globally (see the escape
          # branch in `find_duplicated_keys`, whose allow-list includes this context).
          in_container_quoted_string: {
            '"' => :in_container_value,
            /./mu => :in_container_quoted_string
          },
          # One char after a `/` inside a container: `*`/`/` confirm a comment (which resumes the container once
          # it ends), anything else means the `/` was just a value character and we stay in the container.
          maybe_container_comment: {
            /\*/u => :in_block_comment,
            '/' => :in_line_comment,
            /./mu => :in_container_value
          }
        }.freeze

        # Inspects the given `.strings` file for duplicated keys, returning them if any.
        #
        # @param [String] file The path to the file to inspect.
        # @return [Hash<String, Array<Int>] Hash with the duplicated keys.
        #         Each element has the duplicated key (from the `.strings`) as key and an array of line numbers where the key occurs as value.
        def self.find_duplicated_keys(file:)
          keys_with_lines = Hash.new { |h, k| h[k] = [] }

          state = State.new(context: :root, buffer: StringIO.new, in_escaped_ctx: false, found_key: nil, resume_context: :root, depth: 0)

          # Using our `each_utf8_line` helper instead of `File.readlines` ensures we can also read files that are
          # encoded in UTF-16, yet process each of their lines as a UTF-8 string, so that `RegExp#match?` don't throw
          # an `Encoding::CompatibilityError` exception. (Note how all our `RegExp`s in `TRANSITIONS` have the `u` flag)
          Fastlane::Helper::Ios::L10nHelper.read_utf8_lines(file).each_with_index do |line, line_no|
            line.chars.each_with_index do |c, col_no|
              # Handle escaped characters at a global level.
              # This is more straightforward than having to account for it in the `TRANSITIONS` table.
              if state.in_escaped_ctx || c == '\\'
                # Just because we check for escaped characters at the global level, it doesn't mean we allow them in every context.
                allowed_contexts_for_escaped_characters = %i[in_quoted_key in_quoted_value in_block_comment in_line_comment in_container_quoted_string]
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

        # Detects the file format and, when applicable, scans for duplicate keys — in one step, so
        # callers don't each re-implement the "`:text`-only" gate. `find_duplicated_keys` only
        # understands the flat ASCII-plist syntax; an xml/binary plist can't be tokenized by it (though
        # `plutil` collapses any duplicate to its last value when parsing those anyway).
        #
        # @param [String] file The path to the `.strings` file to inspect.
        # @param [Boolean] assume_valid Forwarded to `strings_file_type`: skip the redundant `plutil -lint`
        #        when the caller has already confirmed the file parses.
        # @return [Array] A `[status, payload]` pair, one of:
        #         - `[:scanned, { key => [lines] }]` — a `:text` file we tokenized (hash empty if none).
        #         - `[:unsupported_format, format]` — not a `:text` file (`:xml`, `:binary`, or `nil`); not scanned.
        #         - `[:unscannable, error_message]` — a `:text` file the tokenizer couldn't read.
        #         Each caller decides how to react (warn-and-skip, fail closed, …) from this one source of truth.
        def self.scan_for_duplicate_keys(file:, assume_valid: false)
          format = Fastlane::Helper::Ios::L10nHelper.strings_file_type(path: file, assume_valid: assume_valid)
          return [:unsupported_format, format] unless format == :text

          [:scanned, find_duplicated_keys(file: file)]
        rescue StandardError => e
          [:unscannable, e.message]
        end

        # Rewrites `.strings` lines so every key carries `prefix`, leaving comments, values, whitespace and
        # formatting untouched. A quoted key gets the prefix inside its quotes (`"key"` → `"<prefix>key"`); an
        # unquoted key is wrapped in quotes (`key` → `"<prefix>key"`). Because it tokenizes the file the same way
        # `find_duplicated_keys` does, it is comment-aware: a key sitting behind an inter-token comment (e.g.
        # `key /* note */ = value;`) is still prefixed, and `key = value`-looking text *inside* a comment is left
        # alone — a distinction a line-based regex can't reliably make. It is likewise container-aware: a
        # dictionary or array value (`"k" = { … };` / `"k" = ( … );`, nesting allowed) has only its outer key
        # prefixed, with the value — including any keys *inside* it — copied through verbatim.
        #
        # @param [Array<String>] lines The file's lines, already decoded to UTF-8 (e.g. via `L10nHelper.read_utf8_lines`).
        # @param [String] prefix The prefix to insert before every key. A nil/empty prefix returns `lines` unchanged.
        # @return [Array<String>] The rewritten lines.
        def self.prefix_keys(lines:, prefix:)
          return lines if prefix.nil? || prefix.empty?

          state = State.new(context: :root, buffer: StringIO.new, in_escaped_ctx: false, found_key: nil, resume_context: :root, depth: 0)
          lines.map do |line|
            rewritten = +''
            line.each_char do |c|
              # Escaped characters only occur inside quoted strings or comments — never around a key boundary —
              # so they're copied through verbatim (mirroring `find_duplicated_keys`' global escape handling).
              if state.in_escaped_ctx || c == '\\'
                state.in_escaped_ctx = !state.in_escaped_ctx
                rewritten << c
                next
              end

              previous_context = state.context
              (_, transition) = TRANSITIONS[previous_context].find { |regex, _| c.match?(regex) } || [nil, nil]
              raise "Invalid character `#{c}` found (current context: #{previous_context})" if transition.nil?

              state.context = transition.is_a?(Proc) ? transition.call(state, c) : transition

              if previous_context == :root && state.context == :in_quoted_key
                rewritten << c << prefix # opening `"` of a quoted key — the prefix goes inside the quotes
              elsif previous_context == :root && state.context == :in_unquoted_key
                rewritten << '"' << prefix << c    # first char of an unquoted key — open a quote + prefix, then the char
              elsif previous_context == :in_unquoted_key && state.context != :in_unquoted_key
                rewritten << '"' << c              # the unquoted key just ended — close the quote, then the delimiter
              else
                rewritten << c
              end
            end
            rewritten
          end
        end
      end
    end
  end
end
