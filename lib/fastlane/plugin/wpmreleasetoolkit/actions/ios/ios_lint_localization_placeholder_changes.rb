# frozen_string_literal: true

require 'fastlane/action'
require_relative '../../helper/string_placeholders_helper'
require_relative '../../helper/ios/ios_l10n_helper'
require_relative '../../helper/ios/ios_strings_file_validation_helper'

module Fastlane
  module Actions
    class IosLintLocalizationPlaceholderChangesAction < Action
      def self.run(params)
        # Parse and validate both inputs first, so a genuinely invalid file (a non-dictionary plist, an
        # unparseable file) surfaces an accurate input error rather than tripping the duplicate-key
        # scanner below and reporting it as a duplicate-check failure.
        old_strings = read_strings(params[:old_file])
        new_strings = read_strings(params[:new_file])

        # Duplicate keys must be caught *before the comparison*: `plutil` silently keeps only the last
        # value for a duplicated key, so a duplicate could hide a real placeholder change. They always
        # abort — independently of `abort_on_violations`, which only governs *placeholder changes* —
        # because the comparison itself is unreliable until each key is defined exactly once.
        if params[:check_duplicate_keys]
          duplicate_keys = duplicate_keys_by_file(params)
          unless duplicate_keys.empty?
            report_duplicate_keys(duplicate_keys)
            UI.abort_with_message!(duplicate_keys_abort_message(duplicate_keys))
          end
        end

        # A value mixing positional (`%1$@`) and non-positional (`%@`) placeholders is invalid —
        # printf/`NSString` require all-or-nothing positional — so its placeholder signature has no
        # well-defined argument order and can't be compared. Always abort (like duplicate keys, and
        # independently of `abort_on_violations`): the comparison itself is unreliable for such a value.
        mixed_keys = mixed_operator_keys_by_file(params[:old_file] => old_strings, params[:new_file] => new_strings)
        unless mixed_keys.empty?
          report_mixed_operators(mixed_keys)
          UI.abort_with_message!(mixed_operators_abort_message(mixed_keys))
        end

        violations = Fastlane::Helper::StringPlaceholdersHelper.incompatible_placeholder_changes(old_strings, new_strings)
        report(violations)

        UI.abort_with_message!(abort_message(violations.length)) if !violations.empty? && params[:abort_on_violations]

        violations
      end

      # Reads a `.strings` file into a `{ key => value }` hash. A malformed file is an *input* error
      # (like a missing file), so surface a clean, user-facing message naming it rather than letting a
      # raw `plutil` stderr dump escape the lane. `read_strings_file_as_hash` shells out to `plutil`,
      # which handles text/XML/binary plists, so this only trips on genuinely unparseable input.
      def self.read_strings(path)
        strings =
          begin
            Fastlane::Helper::Ios::L10nHelper.read_strings_file_as_hash(path: path)
          rescue StandardError => e
            UI.user_error!("Could not parse `#{File.basename(path)}` as a `.strings` file. #{e.message.strip}")
          end
        return strings if strings.is_a?(Hash)

        UI.user_error!("`#{File.basename(path)}` is not a valid `.strings` file (expected a dictionary of key/value pairs).")
      end

      def self.report(violations)
        if violations.empty?
          UI.success('No incompatible placeholder changes found between the two versions of the strings file.')
          return
        end

        violations.each do |violation|
          UI.error <<~MSG
            `#{violation[:key]}` changed its format placeholders incompatibly:
                was: #{violation[:old].inspect}  [#{describe_signature(violation[:old_signature])}]
                now: #{violation[:new].inspect}  [#{describe_signature(violation[:new_signature])}]
          MSG
        end
      end

      def self.describe_signature(signature)
        signature.empty? ? 'no placeholders' : signature
      end

      def self.abort_message(count)
        <<~MSG
          #{count} localization key(s) changed their format placeholders incompatibly.

          Existing translations are keyed by the string's key, not its English text, so changing
          the placeholders of an existing key would silently break every translation for that key.
          Give the changed copy a brand new key instead, so the previous translations stay valid
          for the previous key and the new copy gets translated from scratch.
        MSG
      end

      # Finds duplicate keys in the old and new files, returned as `{ path => { key => [lines] } }`,
      # only including files that actually have duplicates. Format detection and scanning are delegated
      # to `StringsFileValidationHelper.scan_for_duplicate_keys`; `duplicate_keys_in` maps each outcome.
      def self.duplicate_keys_by_file(params)
        [params[:old_file], params[:new_file]].uniq.each_with_object({}) do |path, result|
          duplicates = duplicate_keys_in(path)
          result[path] = duplicates unless duplicates.empty?
        end
      end

      def self.duplicate_keys_in(path)
        # `run` has already parsed both files via `read_strings`, so the plist is known-valid here —
        # `assume_valid: true` skips the redundant `plutil -lint` inside the format check.
        status, payload = Fastlane::Helper::Ios::StringsFileValidationHelper.scan_for_duplicate_keys(file: path, assume_valid: true)
        case status
        when :scanned then payload
        # A non-`:text` plist (xml/binary) has no tokenizer here, but `plutil` collapses any duplicate to
        # its last value when parsing it, and toolkit-generated XML is built from a Hash and is dup-free
        # anyway — so there's nothing to catch.
        when :unsupported_format then {}
        # A `:text` file `plutil` parses but our scanner can't tokenize (e.g. a nested dictionary/array
        # value — valid old-style plist, but not a flat `.strings`). We can't guarantee each key is defined
        # exactly once, and `plutil` keeps only the *last* value for a duplicate, so proceeding could
        # compare the wrong value and miss a real placeholder change. Fail closed rather than compare blindly.
        when :unscannable then UI.abort_with_message!(unverifiable_duplicates_abort_message(path, payload))
        end
      end

      # Emits one `UI.error` per file in a `{ path => { key => detail } }` hash: a headline naming the
      # file and the offending-key count, then one indented line per key formatted by the given block.
      def self.report_per_file(by_path, headline:, &entry)
        by_path.each do |path, entries|
          UI.error <<~MSG
            `#{File.basename(path)}` #{headline.call(entries.count)}:
            #{entries.map(&entry).join("\n")}
          MSG
        end
      end

      def self.report_duplicate_keys(duplicate_keys)
        report_per_file(duplicate_keys, headline: ->(count) { "defines #{count} key(s) more than once" }) do |key, lines|
          "    `#{key}` at lines #{lines.join(', ')}"
        end
      end

      def self.duplicate_keys_abort_message(duplicate_keys)
        count = duplicate_keys.values.sum(&:count)
        <<~MSG
          #{count} localization key(s) are defined more than once in the source strings.

          Parsing `.strings` files relies on `plutil`, which silently keeps only the *last* value for
          a duplicated key. This check would therefore compare against the wrong value and could miss a
          real, translation-breaking placeholder change — the exact failure it exists to catch. Define
          each key exactly once and regenerate the file before re-running this check.
        MSG
      end

      def self.unverifiable_duplicates_abort_message(path, error_message)
        <<~MSG
          Could not verify `#{File.basename(path)}` for duplicate keys: #{error_message.strip}

          Parsing `.strings` files relies on `plutil`, which silently keeps only the *last* value for a
          duplicated key, so this action guards against a duplicate hiding a real placeholder change. The
          file parses as text but our duplicate-key scanner couldn't tokenize it, so that guarantee can't
          be established and the comparison would be unreliable. Make sure the file is a flat `.strings`
          (each line a `key = value;` pair), or pass `check_duplicate_keys: false` to skip this check.
        MSG
      end

      # Finds keys whose value mixes positional and non-positional placeholders, per file, returned as
      # `{ path => { key => value } }`, only including files that have any.
      def self.mixed_operator_keys_by_file(strings_by_path)
        strings_by_path.each_with_object({}) do |(path, strings), result|
          mixed = strings.select { |_key, value| Fastlane::Helper::StringPlaceholdersHelper.mixed_operators?(value) }
          result[path] = mixed unless mixed.empty?
        end
      end

      def self.report_mixed_operators(mixed_keys)
        report_per_file(mixed_keys, headline: ->(count) { "has #{count} key(s) that mix positional and non-positional placeholders" }) do |key, value|
          "    `#{key}`: #{value.inspect}"
        end
      end

      def self.mixed_operators_abort_message(mixed_keys)
        count = mixed_keys.values.sum(&:count)
        <<~MSG
          #{count} localization key(s) mix positional (`%1$@`) and non-positional (`%@`) placeholders in a single value.

          Mixing the two in one format string is invalid — `printf`/`NSString` require either all-positional
          or all-non-positional — so the placeholder shape can't be compared reliably. Give every placeholder
          an explicit `%N$` position, or none, and regenerate the file before re-running this check.
        MSG
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Checks that no existing localization key changed its format placeholders between two versions of a source `.strings` file'
      end

      def self.details
        <<~DETAILS
          Compares two versions (old vs new) of the same base-language `.strings` file and reports any
          key — present in both — whose format placeholders (`%@`, `%1$d`, …) changed in count, position,
          or argument type.

          This is the temporal counterpart to `ios_lint_localizations` (which compares each translation
          against the base language at a single point in time). Translations are filed by key, not by
          English text, so changing the placeholders of an existing key silently breaks every translation
          of that key. New and removed keys are ignored on purpose: copy that needs different placeholders
          is expected to land under a brand new key.

          By default it also aborts if either input file defines the same key more than once: `plutil`
          silently keeps only the last value for a duplicated key, which would let a duplicate hide a
          real placeholder change. Disable this with `check_duplicate_keys: false`.

          Note: parsing `.strings` files relies on `plutil`, so this action only runs on macOS.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :old_file,
            env_name: 'FL_IOS_LINT_L10N_PLACEHOLDER_CHANGES_OLD_FILE',
            description: 'Path to the previous version of the base-language `.strings` file',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("`old_file` not found at path: #{value}") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :new_file,
            env_name: 'FL_IOS_LINT_L10N_PLACEHOLDER_CHANGES_NEW_FILE',
            description: 'Path to the newly-generated version of the base-language `.strings` file',
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("`new_file` not found at path: #{value}") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :abort_on_violations,
            env_name: 'FL_IOS_LINT_L10N_PLACEHOLDER_CHANGES_ABORT',
            description: 'Should we abort the rest of the lane with a global error if any incompatible changes are found?',
            optional: true,
            default_value: true,
            type: Boolean
          ),
          FastlaneCore::ConfigItem.new(
            key: :check_duplicate_keys,
            env_name: 'FL_IOS_LINT_L10N_PLACEHOLDER_CHANGES_CHECK_DUPLICATE_KEYS',
            description: 'Abort if either input file defines the same key more than once. `plutil` keeps only the last value for a duplicated key, which would otherwise let a duplicate silently hide a real placeholder change',
            optional: true,
            default_value: true,
            type: Boolean
          ),
        ]
      end

      def self.return_type
        :array
      end

      def self.return_value
        'An array of incompatible changes, each a hash with the keys `:key`, `:old`, `:new`, `:old_signature` and `:new_signature`. Empty if there are no incompatible changes.'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        %i[ios mac].include?(platform)
      end
    end
  end
end
