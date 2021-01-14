module Fastlane
  module Actions    
    class IosUpdateReleaseNotesAction < Action
      def self.run(params)
        UI.message "Updating the release notes..."

        require_relative '../../helper/ios/ios_git_helper.rb'
        require_relative '../../helper/ios/ios_version_helper.rb'
        next_version = Fastlane::Helpers::IosVersionHelper.calc_next_release_version(params[:new_version])
        Fastlane::Helpers::IosGitHelper.update_release_notes(next_version)
          
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
                                    env_name: "FL_IOS_UPDATE_RELEASE_NOTES_VERSION", 
                                    description: "The version we are currently freezing; An empty entry for the _next_ version after this one will be added to the release notes",
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
        platform == :ios
      end
    end
  end
end