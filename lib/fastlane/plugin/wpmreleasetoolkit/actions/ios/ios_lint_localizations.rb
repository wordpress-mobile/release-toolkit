module Fastlane
  module Actions
    class IosLintLocalizationsAction < Action
      def self.run(params)
        violations = nil

        loop do
          violations = self.run_linter(params)
          violations.default = [] # Set the default value for when querying a missing key

          if params[:check_duplicate_keys]
            find_duplicated_keys(params).each do |language, duplicates|
              violations[language] += duplicates
            end
          end

          report(violations: violations, base_lang: params[:base_lang])
          break unless !violations.empty? && params[:allow_retry] && UI.confirm(RETRY_MESSAGE)
        end

        UI.abort_with_message!(ABORT_MESSAGE) if !violations.empty? && params[:abort_on_violations]

        violations
      end

      def self.run_linter(params)
        UI.message 'Linting localizations for parameter placeholders consistency...'

        require_relative '../../helper/ios/ios_l10n_linter_helper'
        helper = Fastlane::Helper::Ios::L10nLinterHelper.new(
          install_path: resolve_path(params[:install_path]),
          version: params[:version]
        )

        helper.run(
          input_dir: resolve_path(params[:input_dir]),
          base_lang: params[:base_lang],
          only_langs: params[:only_langs]
        )
      end

      def self.report(violations:, base_lang:)
        violations.each do |lang, lang_violations|
          UI.error "Inconsistencies found between '#{base_lang}' and '#{lang}':\n\n#{lang_violations.join("\n")}\n"
        end
      end

      def self.find_duplicated_keys(params)
        duplicate_keys = {}

        files_to_lint = Dir.glob('*.lproj/Localizable.strings', base: params[:input_dir])
        files_to_lint.each do |file|
          language = File.basename(File.dirname(file), '.lproj')
          path = File.join(params[:input_dir], file)

          file_type = Fastlane::Helper::Ios::L10nHelper.strings_file_type(path: path)
          if file_type == :text
            duplicates = Fastlane::Helper::Ios::StringsFileValidationHelper.find_duplicated_keys(file: path)
            duplicate_keys[language] = duplicates.map { |key, value| "`#{key}` was found at multiple lines: #{value.join(', ')}" } unless duplicates.empty?
          else
            UI.warning <<~WRONG_FORMAT
              File `#{path}` is in #{file_type} format, while finding duplicate keys only make sense on files that are in ASCII-plist format.
              Since your files are in #{file_type} format, you should probably disable the `check_duplicate_keys` option from this `#{self.action_name}` call.
            WRONG_FORMAT
          end
        end

        duplicate_keys
      end

      RETRY_MESSAGE = <<~MSG
        Inconsistencies found during Localization linting.
        You need to fix them before continuing. From this point on, you should either:

        - Cancel this lane (reply 'No' below), then work with polyglots in #i18n
          to fix those directly in GlotPress – by rejecting the inconsistent
          translations, or by submitting a fixed copy. Rerun the lane when everything
          has been fixed.

          This is the recommended way to go, as it will fix the issues at their source.

        - Or manually edit the `Localizable.strings` files to fix the inconsistencies
          locally, commit them, then reply 'Yes' below to re-lint and validate that all
          inconsistencies have been fixed locally so you can continue with the build.

          This is only a workaround to allow you to submit a build if translators are
          not available to help you fix the issues in GlotPress in time. You will still
          need to let the translators know that they will need to fix those copies
          at some point before the next build to fix the root of the issue.

        Did you fix the `.strings` files locally and want to lint them again?
      MSG

      ABORT_MESSAGE = <<~MSG
        Inconsistencies found during Localization linting. Aborting.
      MSG

      def self.repo_root
        @repo_root || `git rev-parse --show-toplevel`.chomp
      end

      # If the path is relative, makes the path absolute by resolving it relative to the repository's root.
      # If the path is already absolute, it will not affect it and return it as-is.
      def self.resolve_path(path)
        File.absolute_path(path, repo_root)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Lint the different *.lproj/.strings files for each locale and ensure the parameter placeholders are consistent.'
      end

      def self.details
        'Compares the translations against a base language to find potential mismatches for the %s/%d/… parameter placeholders between locales.'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :install_path,
            env_name: 'FL_IOS_LINT_TRANSLATIONS_INSTALL_PATH',
            description: 'The path where to install the SwiftGen tooling needed to run the linting process. If a relative path, should be relative to your repo_root',
            type: String,
            optional: true,
            default_value: "vendor/swiftgen/#{Fastlane::Helper::Ios::L10nLinterHelper::SWIFTGEN_VERSION}"
          ),
          FastlaneCore::ConfigItem.new(
            key: :version,
            env_name: 'FL_IOS_LINT_TRANSLATIONS_SWIFTGEN_VERSION',
            description: 'The version of SwiftGen to install and use for linting',
            type: String,
            optional: true,
            default_value: Fastlane::Helper::Ios::L10nLinterHelper::SWIFTGEN_VERSION
          ),
          FastlaneCore::ConfigItem.new(
            key: :input_dir,
            env_name: 'FL_IOS_LINT_TRANSLATIONS_INPUT_DIR',
            description: 'The path to the directory containing the .lproj folders to lint, relative to your git repo root',
            type: String,
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :base_lang,
            env_name: 'FL_IOS_LINT_TRANSLATIONS_BASE_LANG',
            description: 'The language that should be used as the base language that every other language will be compared against',
            type: String,
            optional: true,
            default_value: Fastlane::Helper::Ios::L10nLinterHelper::DEFAULT_BASE_LANG
          ),
          FastlaneCore::ConfigItem.new(
            key: :only_langs,
            env_name: 'FL_IOS_LINT_TRANSLATIONS_ONLY_LANGS',
            description: 'The list of languages to limit the analysis to',
            type: Array,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :abort_on_violations,
            env_name: 'FL_IOS_LINT_TRANSLATIONS_ABORT',
            description: 'Should we abort the rest of the lane with a global error if any violations are found?',
            optional: true,
            default_value: true,
            is_string: false # https://docs.fastlane.tools/advanced/actions/#boolean-parameters
          ),
          FastlaneCore::ConfigItem.new(
            key: :allow_retry,
            env_name: 'FL_IOS_LINT_TRANSLATIONS_ALLOW_RETRY',
            description: 'If any violations are found, show an interactive prompt allowing the user to manually fix the issues locally and retry the linting',
            optional: true,
            default_value: false,
            is_string: false # https://docs.fastlane.tools/advanced/actions/#boolean-parameters
          ),
          FastlaneCore::ConfigItem.new(
            key: :check_duplicate_keys,
            env_name: 'FL_IOS_LINT_TRANSLATIONS_CHECK_DUPLICATE_KEYS',
            description: 'Checks the input files for duplicate keys',
            optional: true,
            default_value: true,
            is_string: false # https://docs.fastlane.tools/advanced/actions/#boolean-parameters
          ),
        ]
      end

      def self.output
        nil
      end

      def self.return_type
        :hash
      end

      def self.return_value
        'A hash, keyed by language code, whose values are arrays of violations found for that language'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
