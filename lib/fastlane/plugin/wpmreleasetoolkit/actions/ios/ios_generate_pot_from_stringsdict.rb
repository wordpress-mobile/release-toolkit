# frozen_string_literal: true

require_relative '../../helper/ios/ios_stringsdict_helper'

module Fastlane
  module Actions
    class IosGeneratePotFromStringsdictAction < Action
      def self.run(params)
        output_path = params[:output_path]

        UI.message "Generating `#{output_path}` from #{Array(params[:stringsdict_paths]).inspect}"
        count = Fastlane::Helper::Ios::StringsdictHelper.generate_pot(
          stringsdict_paths: params[:stringsdict_paths],
          output_path: output_path
        )

        UI.success "Generated #{count} plural entr#{count == 1 ? 'y' : 'ies'} into `#{output_path}`."
        count
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Generate a gettext `.pot` template from one or more iOS `.stringsdict` plural files'
      end

      def self.details
        <<~DETAILS
          Converts the plural rules declared in one or more (English source) `.stringsdict`
          files into a gettext `.pot` template suitable for upload to a translation system
          such as GlotPress.

          Each plural variable becomes one `msgid`/`msgid_plural` entry — the English `one`
          form becomes the `msgid` and the `other` form becomes the `msgid_plural`. Entries
          are keyed by a deterministic `msgctxt` (the `.stringsdict` key for single-variable
          entries, or `key:variable` for entries that reference multiple plural variables).

          Only the `one` and `other` forms are converted. Any other CLDR category in the
          source — including an explicit `zero` literal override (e.g. "No items" for a
          count of 0) — has no gettext equivalent, so it is dropped from the `.pot` and a
          warning is logged. Handle such count-specific messages as dedicated strings
          selected in code (e.g. `if count == 0`) rather than as `zero`/`two`/… keys in a
          `.stringsdict` bound for this pipeline.

          Use `ios_generate_stringsdict_from_po` to convert the translated `.po` files back
          into per-locale `.stringsdict` files once translation is complete.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :stringsdict_paths,
            env_name: 'FL_IOS_GENERATE_POT_FROM_STRINGSDICT_PATHS',
            description: 'Path (String) or paths (Array of String) to the source `.stringsdict` file(s) to convert',
            optional: false,
            skip_type_validation: true, # Accept either a String or an Array of String
            verify_block: proc do |value|
              paths = Array(value)
              UI.user_error!('You must provide at least one `.stringsdict` path') if paths.empty?
              paths.each do |path|
                UI.user_error!("Stringsdict file not found: #{path}") unless File.exist?(path)
              end
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :output_path,
            env_name: 'FL_IOS_GENERATE_POT_FROM_STRINGSDICT_OUTPUT_PATH',
            description: 'The path of the `.pot` file to generate',
            type: String,
            optional: false
          ),
        ]
      end

      def self.return_type
        :int
      end

      def self.return_value
        'The number of plural entries written to the `.pot` file'
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
