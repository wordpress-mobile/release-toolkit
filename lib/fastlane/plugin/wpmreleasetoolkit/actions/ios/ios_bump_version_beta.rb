module Fastlane
  module Actions
    class IosBumpVersionBetaAction < Action
      def self.run(params)
        UI.message "Bumping app release version..."
         
        require_relative '../../helper/ios/ios_git_helper.rb'
        require_relative '../../helper/ios/ios_version_helper.rb'

        Fastlane::Helper::IosGitHelper.check_on_branch("release")
        create_config()
        show_config()

        UI.message "Updating XcConfig..."
        Fastlane::Helper::IosVersionHelper.update_xc_configs(@new_beta_version, @short_version, @new_internal_version) 
        UI.message "Done!"
 
        Fastlane::Helper::IosGitHelper.bump_version_beta        
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
        platform == :ios
      end

      private 
      def self.create_config()
        @current_version = Fastlane::Helper::IosVersionHelper.get_build_version()
        @current_version_internal = Fastlane::Helper::IosVersionHelper.get_internal_version() unless ENV["INTERNAL_CONFIG_FILE"].nil?
        @new_internal_version = Fastlane::Helper::IosVersionHelper.create_internal_version(@current_version) unless ENV["INTERNAL_CONFIG_FILE"].nil?
        @new_beta_version = Fastlane::Helper::IosVersionHelper.calc_next_build_version(@current_version)
        @short_version = Fastlane::Helper::IosVersionHelper.get_short_version_string(@new_beta_version)
      end

      def self.show_config()
        UI.message("Current build version: #{@current_version}")
        UI.message("Current internal version: #{@current_version_internal}") unless ENV["INTERNAL_CONFIG_FILE"].nil?
        UI.message("New beta version: #{@new_beta_version}")
        UI.message("New internal version: #{@new_internal_version}") unless ENV["INTERNAL_CONFIG_FILE"].nil?
      end
    end
  end
end