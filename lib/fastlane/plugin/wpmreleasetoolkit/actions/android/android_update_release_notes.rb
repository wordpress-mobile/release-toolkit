module Fastlane
    module Actions    
      class AndroidUpdateReleaseNotesAction < Action
        def self.run(params)
          UI.message "Updating the release notes..."
  
          require_relative '../../helper/android/android_git_helper.rb'
          require_relative '../../helper/android/android_version_helper.rb'
          next_version = Fastlane::Helpers::AndroidVersionHelper.calc_next_release_short_version(params[:new_version])
          Fastlane::Helpers::AndroidGitHelper.update_release_notes(next_version)
            
          UI.message "Done."
        end
    
        #####################################################
        # @!group Documentation
        #####################################################
    
        def self.description
          "Updates the release notes file for the next app version"
        end
    
        def self.details
          "Updates the release notes file for the next app version"
        end
    
        def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :new_version,
                                      env_name: "FL_ANDROID_UPDATE_RELEASE_NOTES_VERSION", 
                                      description: "The new version to add to the release notes",
                                      is_string: true)
        ]
        end
  
        def self.output
            
        end
    
        def self.return_value
            
        end
    
        def self.authors
          ["loremattei"]
        end
    
        def self.is_supported?(platform)
          platform == :android
        end
      end
    end
  end