module Fastlane
  module Actions
    class IosLintLocalizationsAction < Action
      def self.run(params)
        violations = {}

        loop do
          violations = self.run_linter(params)
          break unless !violations.empty? && params[:allow_retry] && UI.confirm(RETRY_MESSAGE)
        end

        if !violations.empty? && params[:abort_on_violations]
          UI.abort_with_message!(ABORT_MESSAGE)
        end

        violations
      end

      def self.run_linter(params)
        UI.message 'Linting localizations for parameter placeholders consistency...'

        require_relative '../../helper/ios/ios_l10n_helper.rb'
        helper = Fastlane::Helper::Ios::L10nHelper.new(
          install_path: resolve_path(params[:install_path]),
          version: params[:version]
        )
        violations = helper.run(
          input_dir: resolve_path(params[:input_dir]),
          base_lang: params[:base_lang],
          only_langs: params[:only_langs]
        )

        violations.each do |lang, diff|
          UI.error "Inconsistencies found between '#{params[:base_lang]}' and '#{lang}':\n\n#{diff}\n"
        end

        violations
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
            default_value: "vendor/swiftgen/#{Fastlane::Helper::Ios::L10nHelper::SWIFTGEN_VERSION}"
          ),
          FastlaneCore::ConfigItem.new(
            key: :version,
            env_name: 'FL_IOS_LINT_TRANSLATIONS_SWIFTGEN_VERSION',
            description: 'The version of SwiftGen to install and use for linting',
            type: String,
            optional: true,
            default_value: Fastlane::Helper::Ios::L10nHelper::SWIFTGEN_VERSION
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
            default_value: Fastlane::Helper::Ios::L10nHelper::DEFAULT_BASE_LANG
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
        ]
      end

      def self.output
        nil
      end

      def self.return_type
        :hash_of_strings
      end

      def self.return_value
        'A hash, keyed by language code, whose values are the diff found for said language'
      end

      def self.authors
        ['AliSoftware']
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
  end
