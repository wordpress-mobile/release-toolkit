# frozen_string_literal: true

require_relative '../../helper/ios/ios_stringsdict_helper'

module Fastlane
  module Actions
    class IosGenerateStringsdictFromPoAction < Action
      def self.run(params)
        output_path = params[:output_path]

        UI.message "Generating `#{output_path}` for locale `#{params[:locale]}` from `#{params[:po_path]}`"
        missing = Fastlane::Helper::Ios::StringsdictHelper.generate_stringsdict_from_po(
          po_path: params[:po_path],
          template_path: params[:template_path],
          locale: params[:locale],
          output_path: output_path
        )

        missing.each do |context|
          UI.important "No translation for `#{context}` in `#{params[:po_path]}` — kept the source (English) value."
        end
        UI.success "Generated `#{output_path}` for locale `#{params[:locale]}`."
        missing
      rescue Fastlane::Helper::Ios::PluralRules::UnknownLocaleError => e
        # Locales with no vetted plural mapping (e.g. Welsh) surface as a clean
        # user error — exclude them from the locales you convert.
        UI.user_error!(e.message)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Generate a localized iOS `.stringsdict` plural file from a translated gettext `.po`'
      end

      def self.details
        <<~DETAILS
          Converts a translated `.po` file (e.g. downloaded from GlotPress) back into an iOS
          `.stringsdict` plural file for a single locale.

          The original English `.stringsdict` is required as a structural template: the `.po`
          only carries the translated strings, while the format key, variable names and
          format specifiers are copied from the template. The `.po`'s indexed `msgstr[N]`
          plural forms are mapped back to CLDR plural-category names (`one`, `few`, `many`, …)
          according to the locale's plural rules.

          This is the counterpart to `ios_generate_pot_from_stringsdict`.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :po_path,
            env_name: 'FL_IOS_GENERATE_STRINGSDICT_FROM_PO_PO_PATH',
            description: 'The path to the translated `.po` file for the locale',
            type: String,
            optional: false,
            verify_block: proc do |value|
              UI.user_error!("PO file not found: #{value}") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :template_path,
            env_name: 'FL_IOS_GENERATE_STRINGSDICT_FROM_PO_TEMPLATE_PATH',
            description: 'The path to the original (English) `.stringsdict` to use as a structural template',
            type: String,
            optional: false,
            verify_block: proc do |value|
              UI.user_error!("Stringsdict template not found: #{value}") unless File.exist?(value)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :locale,
            env_name: 'FL_IOS_GENERATE_STRINGSDICT_FROM_PO_LOCALE',
            description: "The locale code of the `.po` file (e.g. 'ru', 'pt-BR'), used to map plural indices to CLDR categories",
            type: String,
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :output_path,
            env_name: 'FL_IOS_GENERATE_STRINGSDICT_FROM_PO_OUTPUT_PATH',
            description: 'The path of the localized `.stringsdict` file to generate',
            type: String,
            optional: false
          ),
        ]
      end

      def self.return_type
        :array_of_strings
      end

      def self.return_value
        'The list of translation contexts that had no translation in the `.po` (filled from the English source)'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        %i[ios mac].include? platform
      end
    end
  end
end
