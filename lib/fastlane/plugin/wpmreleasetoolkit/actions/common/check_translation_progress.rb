module Fastlane
  module Actions
    class CheckTranslationProgressAction < Action
      def self.run(params)
        under_threshold_langs = {}

        UI.message('Check translations status...')

        params[:language_codes].each do | language_code |
          under_threshold_langs << self.check_language(
                                      language_code, 
                                      params[:min_acceptable_translation_percentage], 
                                      params[:abort_on_violations])
        end

        
      end

      def self.check_language(language_code, min_acceptable_translation_percentage, abort_on_violations)
        
      end
      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Raises an error if the translation percentage is lower than the provided threshold.'
      end

      def self.details
        'This actions checks the current status of the translations on GlotPress ' \
        'and raises an error if it\'s below the provided threshold'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :glotpress_url,
                                       env_name: 'FL_CHECK_TRANSLATION_PROGRESS_GLOTPRESS_URL',
                                       description: 'URL to the GlotPress project',
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :language_codes,
                                       env_name: 'FL_CHECK_TRANSLATION_PROGRESS_LANGUAGE_CODES',
                                       description: 'The list of the codes of the languages to check.',
                                       type: Array,
                                       optional: true,
                                       # Default to Mag16. 
                                       default_value: "ar de es fr he id it ja ko nl pt-br ru sv tr zh-cn zh-tw".split()),
          FastlaneCore::ConfigItem.new(key: :min_acceptable_translation_percentage,
                                       env_name: 'FL_CHECK_TRANSLATION_PROGRESS_MIN_ACCEPTABLE_TRANSLATION_PERCENTAGE',
                                       description: 'The threshold under which an error is raised.',
                                       type: Integer,
                                       optional: true,
                                       default_value: 100),
          FastlaneCore::ConfigItem.new(key: :abort_on_violations,
                                       env_name: 'FL_CHECK_TRANSLATION_ABORT_ON_VIOLATIONS',
                                       description: 'Should we abort with a global error if any violations are found?',
                                       optional: true,
                                       default_value: true,
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                       env_name: 'FL_CHECK_TRANSLATION_SKIP_CONFIRM',
                                       description: 'Move ahead without requesting confirmation if violations are found. Only works if "abort_on_violations" is disabled.',
                                       optional: true,
                                       default_value: false,
                                       is_string: false),
        ]
      end

      def self.authors
        ["loremattei"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
