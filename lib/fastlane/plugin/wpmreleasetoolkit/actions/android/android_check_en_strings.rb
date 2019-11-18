module Fastlane
    module Actions
      class AndroidCheckEnStringsAction < Action
        def self.run(params)
          # check local repo status
          other_action.ensure_git_status_clean(show_uncommitted_changes:true)

          # set up test by removing localized strings.xml
          sh("rm -f #{params[:res_dir]}/values-??/strings.xml #{params[:res_dir]}/values-??-r??/strings.xml")
          UI.message("Localized strings have been temporarily deleted to set up for test build.")

          # check for missing strings by doing a build
          UI.message("Checking for missing English strings in #{params[:res_dir]}/values/strings.xml")
          UI.message("Running test build without localized strings, this may take a while...")

          success = true
          sh("./gradlew build > /dev/null", error_callback: ->(result) { success = false })

          # clean build
          sh("./gradlew clean > /dev/null 2>&1")
          sh("git checkout -- #{params[:res_dir]}/")
          "Cleanup complete: build cleaned, localized strings are no longer deleted"

          # report result
          if (!success)
            UI.user_error!("Check Failed: some English strings were missing in #{params[:res_dir]}/values/strings.xml")
          end

          "Check Success: no missing English strings found in #{params[:res_dir]}/values/strings.xml"
        end
        #####################################################
        # @!group Documentation
        #####################################################
    
        def self.description
          "checks values/strings.xml for missing strings (slow)"
        end
    
        def self.details
          "checks values/strings.xml in the specified res directory for missing strings. very slow and requires clean git status."
        end

        def self.available_options
          [
            FastlaneCore::ConfigItem.new(key: :res_dir,
                                         env_name: "FL_ANDROID_RES_DIR", 
                                         description: "specify res directory for values/strings.xml", 
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