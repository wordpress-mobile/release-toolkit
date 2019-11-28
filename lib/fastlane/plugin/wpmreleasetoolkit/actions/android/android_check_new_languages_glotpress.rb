require_relative '../../helper/android_localize_helper'
module Fastlane
    module Actions
      class AndroidCheckNewLanguagesGlotpressAction < Action
        def self.run(params)

          languages_to_check = Fastlane::Helper::AndroidLocalizeHelper.get_glotpress_languages_translated_morethan90_from_url(params[:glotpress_status_url])
          UI.message("Number of languages over 90\% translation threshold: #{languages_to_check.count}")

          language_file_path = "#{Fastlane::Helper::FilesystemHelper::project_path()}/#{params[:language_file]}"
          missing_languages = Fastlane::Helper::AndroidLocalizeHelper.get_missing_languages(languages_to_check, language_file_path, params[:verbose])

          if (not missing_languages.empty?)
            error_message = "Found #{missing_languages.count} " + "language".pluralize(missing_languages.count) + " over 90\% translation but not in #{language_file_path}"
            UI.error("#{error_message}:")

            missing_languages.each do |language_code|
              UI.error("#{language_code}")
            end

            UI.user_error!("Check Failed: #{error_message}")
          end

          UI.success "Check Success: all languages over 90\% translation threshold were found in #{language_file_path}"
          "Check Success"
        end
        #####################################################
        # @!group Documentation
        #####################################################
    
        def self.description
          "checks for potential new languages"
        end
    
        def self.details
          "checks GlotPress status page for languages that have reached 90\% translation threshold that are not in the project."
        end

        def self.available_options
          [
            FastlaneCore::ConfigItem.new(key: :glotpress_status_url,
                                         env_name: "FL_ANDROID_CHECK_NEW_LANG_GLOTPRESS_STATUS_URL",
                                         description: "specify GlotPress translation status url",
                                         is_string: true,
                                         default_value: ""),
            FastlaneCore::ConfigItem.new(key: :language_file,
                                         env_name: "FL_ANDROID_CHECK_NEW_LANG_GLOTPRESS_LANG_FILE",
                                         description: "specify language file",
                                         is_string: true,
                                         default_value: ""),
            FastlaneCore::ConfigItem.new(key: :verbose,
                                         env_name: "FL_ANDROID_CHECK_NEW_LANG_GLOTPRESS_VERBOSE",
                                         description: "specify whether to display more output",
                                         is_string: false,
                                         default_value: true)
          ]
        end
    
        def self.output
            
        end
    
        def self.return_value
            
        end
    
        def self.authors
          ["ravenstewart"]
        end
    
        def self.is_supported?(platform)
          platform == :android
        end
      end
    end
  end