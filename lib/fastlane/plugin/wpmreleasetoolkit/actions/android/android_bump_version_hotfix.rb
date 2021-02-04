module Fastlane
  module Actions
    class AndroidBumpVersionHotfixAction < Action
      def self.run(params)
        UI.message "Bumping app release version for hotfix..."
        
        require_relative '../../helper/android/android_git_helper.rb'
        Fastlane::Helper::GitHelper.create_branch_for_hotfix(params[:previous_version_name], params[:version_name])
        create_config(params[:previous_version_name], params[:version_name], params[:version_code])
        show_config()
        
        UI.message "Updating build.gradle..."
        Fastlane::Helper::Android::VersionHelper.update_versions(@new_version, @current_version_alpha) 
        UI.message "Done!"

        Fastlane::Helper::Android::GitHelper.bump_version_hotfix(params[:version_name])
        
        UI.message "Done."
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Bumps the version of the app and creates the new release branch"
      end

      def self.details
        "Bumps the version of the app and creates the new release branch"
      end

      def self.available_options
        # Define all options your action supports. 
        
        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :version_name,
                                       env_name: "FL_ANDROID_BUMP_VERSION_HOTFIX_VERSION", 
                                       description: "The version of the hotfix", 
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :version_code,
                                        env_name: "FL_ANDROID_BUMP_VERSION_HOTFIX_CODE", 
                                        description: "The version of the hotfix"),
          FastlaneCore::ConfigItem.new(key: :previous_version_name,
                                       env_name: "FL_ANDROID_BUMP_VERSION_HOTFIX_PREVIOUS_VERSION",
                                       description: "The version to branch from",
                                       is_string: true) # the default value if the user didn't provide one
        ]
      end

      def self.authors
        ["loremattei"]
      end

      def self.is_supported?(platform)
        platform == :android
      end

      private 
      def self.create_config(previous_version, new_version_name, new_version_code)
        @current_version = Fastlane::Helper::Android::VersionHelper.get_release_version()
        @current_version_alpha = Fastlane::Helper::Android::VersionHelper.get_alpha_version()
        @new_version = Fastlane::Helper::Android::VersionHelper.calc_next_hotfix_version(new_version_name, new_version_code)
        @new_short_version = new_version_name
        @new_release_branch = "release/#{@new_short_version}"
      end

      def self.show_config()
        UI.message("Current version: #{@current_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}(#{@current_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]})")
        UI.message("New hotfix version: #{@new_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}(#{@new_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]})")
        UI.message("Release branch: #{@new_release_branch}")
      end
    end
  end
end
