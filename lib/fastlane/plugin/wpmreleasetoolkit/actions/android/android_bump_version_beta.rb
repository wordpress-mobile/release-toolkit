module Fastlane
  module Actions
    class AndroidBumpVersionBetaAction < Action
      def self.run(params)
        UI.message "Bumping app release version..."
         
        require_relative '../../helper/android/android_git_helper.rb'
        require_relative '../../helper/android/android_version_helper.rb'

        Fastlane::Helpers::AndroidGitHelper.check_on_branch("release")
        create_config()
        show_config()

        UI.message "Updating build.gradle..."
        Fastlane::Helpers::AndroidVersionHelper.update_versions(@new_version_beta, @new_version_alpha)  
        UI.message "Done!"
 
        Fastlane::Helpers::AndroidGitHelper.bump_version_beta()        
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

      def self.available_options
        
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

      private 
      def self.create_config()
        @current_version = Fastlane::Helpers::AndroidVersionHelper.get_release_version()
        @current_version_alpha = Fastlane::Helpers::AndroidVersionHelper.get_alpha_version()
        @new_version_beta = Fastlane::Helpers::AndroidVersionHelper.calc_next_beta_version(@current_version, @current_version_alpha)
        @new_version_alpha = ENV["HAS_ALPHA_VERSION"].nil? ? nil : Fastlane::Helpers::AndroidVersionHelper.calc_next_alpha_version(@new_version_beta, @current_version_alpha)
      end

      def self.show_config()
        vname = Fastlane::Helpers::AndroidVersionHelper::VERSION_NAME
        vcode = Fastlane::Helpers::AndroidVersionHelper::VERSION_CODE
        UI.message("Current version: #{@current_version[vname]}(#{@current_version[vcode]})")
        UI.message("Current alpha version: #{@current_version_alpha[vname]}(#{@current_version_alpha[vcode]})") unless ENV["HAS_ALPHA_VERSION"].nil?
        UI.message("New beta version: #{@new_version_beta[vname]}(#{@new_version_beta[vcode]})")
        UI.message("New alpha version: #{@new_version_alpha[vname]}(#{@new_version_alpha[vcode]})") unless ENV["HAS_ALPHA_VERSION"].nil?
      end
    end
  end
end