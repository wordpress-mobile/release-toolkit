# frozen_string_literal: true

module Fastlane
  module Helper
    # Platform-agnostic primitive for comparing the placeholder "shape" — the
    # count, position, and argument type of the printf/`NSString` format
    # specifiers — of localized string values.
    #
    # This is purposely **pure Ruby** (no file I/O, no shelling out) so it runs
    # on any platform: the same `%@`/`%1$d`/`%2$s` placeholder syntax is shared by
    # iOS and Android. The platform-specific actions parse their respective file
    # format into a `{ key => value }` hash and then call into this helper.
    #
    # The main use case is a temporal guardrail: when a source-language string is
    # regenerated, an existing key's value must not change its placeholders
    # (e.g. `"%1$@ liked your post"` → `"%1$d people liked your post"`). Existing
    # translations stay filed under the same key, so a placeholder-incompatible
    # change would silently break every translation of that key. Copy that needs
    # different placeholders is expected to land under a brand new key instead.
    #
    module StringPlaceholdersHelper
      # printf / `NSString` conversion characters grouped by the argument type a
      # translation must preserve. Width, precision and length modifiers don't
      # affect the argument type, so they are intentionally not part of the class.
      #
      # `%d` ↔ `%i` is compatible (both consume an `int`); `%d` ↔ `%@` is not
      # (`int` vs `object`).
      CONVERSION_CLASSES = {
        '@' => 'object',
        'd' => 'int', 'i' => 'int', 'u' => 'int', 'o' => 'int', 'x' => 'int', 'X' => 'int',
        'f' => 'float', 'e' => 'float', 'E' => 'float', 'g' => 'float', 'G' => 'float', 'a' => 'float', 'A' => 'float',
        'c' => 'char', 'C' => 'char',
        's' => 'cstring', 'S' => 'cstring',
        'p' => 'pointer'
      }.freeze

      # A single format specifier: a `%`, an optional positional argument (`1$`),
      # flags, width, precision, an optional length modifier, then the conversion
      # character. `%%` (a literal percent) is matched too so it can be explicitly
      # skipped rather than mistaken for a placeholder.
      #
      # The flag class includes the two thousands-grouping flags — C/POSIX `'` (`%'d`) and
      # Java/Android `,` (`%,d`) — alongside the standard `-`, `+`, `0`, `#`. Omitting the grouping
      # flags would drop a real placeholder: `%,d` would match nothing and vanish from the signature, so
      # a count change on an all-grouped string (`"%,d of %,d"` → `"%,d done"`) would be silently missed.
      # Adding or removing a grouping flag stays compatible (it doesn't change the argument type). (Java's
      # `(` accounting flag is intentionally excluded — `%(` collides with parenthetical copy and
      # Python-style `%(name)s`.)
      #
      # The printf space flag (`% d`) is deliberately NOT in the class. A `%` followed by a space is how
      # a *literal* percent reads in real copy (`"50% off"`, `"100% done"`), so recognizing `% d` as a
      # space-flagged specifier would invent a phantom placeholder out of ordinary text — flagging benign
      # copy edits and, worse, masking a real placeholder removal when the phantom happens to match the
      # removed argument's type. Treating a glued `%d` as a specifier but a spaced `% word` as a literal
      # percent matches how localized strings are actually written.
      #
      # `*` dynamic width/precision (`%*d`, `%.*f`) is deliberately NOT matched: it consumes an extra
      # `int` argument that this one-slot-per-specifier model can't represent. Leaving it unrecognized
      # is the safe choice — rather than silently treating `%*d` as compatible with `%d`, a change to
      # or from a `*` specifier surfaces as a difference and gets flagged.
      #
      # Precision is `.` followed by *zero or more* digits, so the valid C "precision 0" form (`%.f`)
      # is recognized as a float rather than silently dropped.
      #
      # `%n` (the write-back conversion) is intentionally NOT in the conversion class: it consumes no
      # printable argument, has no place in a localized string, and is a format-string hazard — so a
      # stray `%n` in copy is treated as a literal percent, not a placeholder.
      SPECIFIER = /%(?<position>\d+\$)?[-+0#,']*\d*(?:\.\d*)?(?:hh|h|ll|l|q|L|z|t|j)?(?<conversion>[@diouxXeEfgGaAcCsSp%])/

      # A canonical signature of the placeholders in a string value.
      #
      # Two values with the same signature are placeholder-compatible. The
      # signature is invariant to benign copy edits, to reordering equivalent
      # positional arguments, and to repeating a positional argument (which still
      # consumes a single argument), but sensitive to a change in the count,
      # position, or argument type of the placeholders.
      #
      # @param [String] value The string value to compute a signature for.
      # @return [String] e.g. `"1:int,2:object"`, or `''` if there are no placeholders.
      #
      def self.placeholder_signature(value)
        # Collapse the specifiers into argument *slots* keyed by position: an explicit `%1$…` keys by
        # its number, a non-positional `%…` by its order of appearance. Keying (rather than listing)
        # means a positional argument referenced more than once (`%1$@ … %1$@`) collapses to a single
        # slot — it still consumes one argument, so it stays compatible with a single `%1$@`. Sorting
        # by position keeps the signature invariant to reordering equivalent positional arguments.
        slots = {}
        extract_specifiers(value).each_with_index do |specifier, index|
          slots[specifier[:position] || (index + 1)] = specifier[:class]
        end
        slots.sort.map { |position, klass| "#{position}:#{klass}" }.join(',')
      end

      # Whether two string values share the same placeholder shape.
      #
      # @param [String] old_value The first value to compare.
      # @param [String] new_value The second value to compare.
      # @return [Boolean] `true` if both values have the same placeholder signature.
      #
      def self.placeholders_compatible?(old_value, new_value)
        placeholder_signature(old_value) == placeholder_signature(new_value)
      end

      # Given two `{ key => value }` hashes, finds the keys present in **both**
      # whose placeholder signature changed.
      #
      # New and removed keys are ignored on purpose: copy that needs a fresh
      # translation is expected to land under a new key (which shows up as
      # remove-old + add-new, not as a change to an existing key).
      #
      # @param [Hash<String,String>] old_strings The previous `{ key => value }` strings.
      # @param [Hash<String,String>] new_strings The new `{ key => value }` strings.
      # @return [Array<Hash>] One entry per incompatible change, sorted by key, each
      #         `{ key:, old:, new:, old_signature:, new_signature: }`.
      #
      def self.incompatible_placeholder_changes(old_strings, new_strings)
        (old_strings.keys & new_strings.keys).sort.filter_map do |key|
          old_signature = placeholder_signature(old_strings[key])
          new_signature = placeholder_signature(new_strings[key])
          next if old_signature == new_signature

          { key: key, old: old_strings[key], new: new_strings[key], old_signature: old_signature, new_signature: new_signature }
        end
      end

      # Whether a value mixes positional (`%1$@`) and non-positional (`%@`) format specifiers in a
      # single string. This is invalid — `printf`/`NSString`/`Formatter` require either all-positional
      # or all-non-positional — so such a value has no well-defined argument order and its
      # `placeholder_signature` can't be trusted. Callers should reject a mixed value rather than
      # compare it.
      #
      # @param [String] value The string value to check.
      # @return [Boolean] `true` if the value contains both a positional and a non-positional specifier.
      #
      def self.mixed_operators?(value)
        specifiers = extract_specifiers(value)
        specifiers.any? { |specifier| specifier[:position] } && specifiers.any? { |specifier| specifier[:position].nil? }
      end

      # The format specifiers found in a value, as an array of
      # `{ position:, class: }` hashes, excluding the literal `%%`.
      # `position` is `nil` for non-positional specifiers.
      #
      # @param [String] value The string value to scan.
      # @return [Array<Hash>] The specifiers, in order of appearance.
      #
      def self.extract_specifiers(value)
        found = []
        value.to_s.scan(SPECIFIER) do
          match = Regexp.last_match
          conversion = match[:conversion]
          next if conversion == '%' # literal percent, not a placeholder

          found << { position: match[:position]&.delete('$')&.to_i, class: CONVERSION_CLASSES.fetch(conversion, conversion) }
        end
        found
      end
      private_class_method :extract_specifiers
    end
  end
end
