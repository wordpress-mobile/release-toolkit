module Fastlane
    module Actions
      class AndroidCheckNewLanguagesGlotPressAction < Action
        def self.run(params)
          UI.message("Checking for potential new languages...")
          curl_command = "curl -L #{params[:glot_press_status_url]} 2> /dev/null"
          grep_commands = "grep -B 1 morethan90 | grep \"android/dev/\""
          sed_command = "sed \"s+.*android/dev/\\([a-zA-Z-]*\\)/default.*+\\1+\""
          languages_to_check = sh("#{curl_command} | #{grep_commands} | #{sed_command}").split(' ')

          UI.message("Number of languages over 90\% translation threshold: #{languages_to_check.count}")

          missing_languages = []
          languages_to_check.each do |language_code|
            found = true
            sh("grep \"^#{language_code},\" #{params[:language_file]} > /dev/null 2>&1", error_callback: ->(result) { found = false })
            if (!found)
              missing_languages = missing_languages << language_code
              success = false
            end
          end

          if (!missing_languages.empty?)
            plural = ""
            if (missing_languages.count > 1)
              plural = "s"
            end

            UI.error("Found #{missing_languages.count} language#{plural} over 90\% translation but are not found in #{params[:language_file]}:");

            missing_languages.each do |language_code|
              UI.error("#{language_code}");
            end

            UI.user_error!("Check Failed: found languages over 90\% translation threshold that are not in #{params[:language_file]}")
          end

          "Check Success: all languages over 90\% translation threshold were found in #{params[:language_file]}"
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
            FastlaneCore::ConfigItem.new(key: :glot_press_status_url,
                                         env_name: "FL_ANDROID_CHECK_NEW_LANG_GLOT_PRESS_STATUS_URL",
                                         description: "specify GlotPress translation status url",
                                         is_string: true,
                                         default_value: ""),
            FastlaneCore::ConfigItem.new(key: :language_file,
                                         env_name: "FL_ANDROID_CHECK_NEW_LANG_GLOT_PRESS_LANG_FILE",
                                         description: "specify language file",
                                         is_string: true,
                                         default_value: "")
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