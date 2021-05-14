module Fastlane
  module Actions
    class CheckTranslationProgressAction < Action
      def self.run(params)

      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Raises an error if the translation percentage is lower than the provided threshold.'
      end

      def self.details
        'This actions checks the current state of the translation on GlotPress ' \
        'and raises an error if it\'s below the provided threshold'
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
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
                                       description: 'Should we abort the rest of the lane with a global error if any violations are found?',
                                       optional: true,
                                       default_value: true,
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
