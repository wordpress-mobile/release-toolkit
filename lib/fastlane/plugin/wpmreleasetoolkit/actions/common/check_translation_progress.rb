module Fastlane
  module Actions
    class CheckTranslationProgressAction < Action
      def self.run(params)
        require_relative '../../helper/glotpress_helper.rb'

        UI.message('Check translations status...')

        under_threshold_langs = check_translations(
                                  params[:glotpress_url], 
                                  params[:language_codes],
                                  params[:abort_on_violations],
                                  params[:min_acceptable_translation_percentage])

        check_results(under_threshold_langs, params[:skip_confirm]) unless under_threshold_langs.length == 0

        UI.message('Done')
      end

      def self.check_translations(glotpress_url, language_codes, abort_on_violations, threshold)
        under_threshold_langs = {}

        language_codes.each do | language_code |
          progress = Fastlane::Helper::GlotPressHelper.get_translation_status(
                                      glotpress_url,
                                      language_code) rescue -1
          
          if (abort_on_violations)
            UI.abort_with_message!("Can't get data for language #{language_code}") if (progress == -1) 
            UI.abort_with_message!("#{language_code} is translated #{progress}% which is under the required #{threshold}%.") \ 
              if (progress < threshold) 
          end
          
          under_threshold_langs << {:lang => language_code, :progress => progress } if (progress < threshold)
        end

        under_threshold_langs
      end

      def self.check_results(under_threshold_langs, threshold, skip_confirm)
        message = "The translations for the following languages are below the #{threshold}% threshold:\n"
        
        under_threshold_langs.each do | lang |
          message << " - #{lang[lang]} is at #{lang[progress]}%.\n"
        end

        skip_confirm ? UI.important(message) : UI.interactive? UI.confirm("#{message}Do you want to continue?") : UI.abort_with_message!(message)
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
