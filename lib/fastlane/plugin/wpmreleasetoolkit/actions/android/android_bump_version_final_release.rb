module Fastlane
  module Actions
    class AndroidBumpVersionFinalReleaseAction < Action
      def self.run(params)
        UI.message "Bumping app release version..."
         
        require_relative '../../helper/android/android_git_helper.rb'
        require_relative '../../helper/android/android_version_helper.rb'

        Fastlane::Helper::AndroidGitHelper.check_on_branch("release")
        create_config()
        show_config()

        UI.message "Updating gradle.properties..."
        Fastlane::Helper::AndroidVersionHelper.update_versions(@final_version, @current_version_alpha)  
        UI.message "Done!"
 
        Fastlane::Helper::AndroidGitHelper.bump_version_final()        
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Bumps the version of the app for a new beta"
      end

      def self.details
        "Bumps the version of the app for a new beta"
      end

      def self.authors
        ["loremattei"]
      end

      def self.is_supported?(platform)
        platform == :android
      end

      private 
      def self.create_config()
        @current_version = Fastlane::Helper::AndroidVersionHelper.get_release_version()
        @current_version_alpha = Fastlane::Helper::AndroidVersionHelper.get_alpha_version()
        @final_version = Fastlane::Helper::AndroidVersionHelper.calc_final_release_version(@current_version, @current_version_alpha)
      end

      def self.show_config()
        vname = Fastlane::Helper::AndroidVersionHelper::VERSION_NAME
        vcode = Fastlane::Helper::AndroidVersionHelper::VERSION_CODE
        UI.message("Current version: #{@current_version[vname]}(#{@current_version[vcode]})")
        UI.message("Current alpha version: #{@current_version_alpha[vname]}(#{@current_version_alpha[vcode]})") unless ENV["HAS_ALPHA_VERSION"].nil?
        UI.message("New release version: #{@final_version[vname]}(#{@final_version[vcode]})")
      end
    end
  end
end