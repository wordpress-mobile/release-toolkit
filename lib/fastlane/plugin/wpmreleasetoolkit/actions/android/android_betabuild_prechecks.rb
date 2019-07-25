module Fastlane
  module Actions
    class AndroidBetabuildPrechecksAction < Action
      def self.run(params)
        UI.message "Skip confirm: #{params[:skip_confirm]}"
        UI.message "Work on version: #{params[:base_version]}" unless params[:base_version].nil?
        
        require_relative '../../helper/android/android_version_helper.rb'
        require_relative '../../helper/android/android_git_helper.rb'

        # Checkout develop and update
        Fastlane::Helpers::AndroidGitHelper::git_checkout_and_pull("develop")

        # Check versions
        release_version = Fastlane::Helpers::AndroidVersionHelper::get_release_version
        message = "The following current version has been detected: #{release_version[Fastlane::Helpers::AndroidVersionHelper::VERSION_NAME]}\n"
        alpha_release_version = Fastlane::Helpers::AndroidVersionHelper::get_alpha_version
        message << "The following Alpha version has been detected: #{alpha_release_version[Fastlane::Helpers::AndroidVersionHelper::VERSION_NAME]}\n" unless alpha_release_version.nil?
        
        # Check branch
        app_version = Fastlane::Helpers::AndroidVersionHelper::get_public_version
        UI.user_error!("#{message}Release branch for version #{app_version} doesn't exist. Abort.") unless (!params[:base_version].nil? || Fastlane::Helpers::AndroidGitHelper::git_checkout_and_pull_release_branch_for(app_version))
        
        # Check user overwrite
        if (!params[:base_version].nil?)
          overwrite_version = get_user_build_version(params[:base_version], message)
          release_version = overwrite_version[0]
          alpha_release_version = overwrite_version[1]
        end

        next_beta_version = Fastlane::Helpers::AndroidVersionHelper::calc_next_beta_version(release_version, alpha_release_version)
        next_alpha_version = Fastlane::Helpers::AndroidVersionHelper::calc_next_alpha_version(release_version, alpha_release_version) unless alpha_release_version.nil?

        # Verify
        message << "Updating branch to version: #{next_beta_version[Fastlane::Helpers::AndroidVersionHelper::VERSION_NAME]}(#{next_beta_version[Fastlane::Helpers::AndroidVersionHelper::VERSION_CODE]}) "
        message << "and #{next_alpha_version[Fastlane::Helpers::AndroidVersionHelper::VERSION_NAME]}(#{next_alpha_version[Fastlane::Helpers::AndroidVersionHelper::VERSION_CODE]}).\n" unless alpha_release_version.nil?
        if (!params[:skip_confirm])
          if (!UI.confirm("#{message}Do you want to continue?"))
            UI.user_error!("Aborted by user request")
          end
        else 
          UI.message(message)
        end

        # Check local repo status
        other_action.ensure_git_status_clean()

        # Return the current version
        [next_beta_version, next_alpha_version]
      end

      def self.get_user_build_version(version, message)
        UI.user_error!("Release branch for version #{version} doesn't exist. Abort.") unless Fastlane::Helpers::AndroidGitHelper::git_checkout_and_pull_release_branch_for(version)
        release_version = Fastlane::Helpers::AndroidVersionHelper::get_release_version
        message << "Looking at branch release/#{version} as requested by user. Detected version: #{release_version[Fastlane::Helpers::AndroidVersionHelper::VERSION_NAME]}.\n"
        alpha_release_version = Fastlane::Helpers::AndroidVersionHelper::get_alpha_version
        message << "and Alpha Version: #{alpha_release_version[Fastlane::Helpers::AndroidVersionHelper::VERSION_NAME]}\n" unless alpha_release_version.nil?
        [release_version, alpha_release_version]
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Runs some prechecks before preparing for a new test build"
      end

      def self.details
        "Updates the relevant release branch, checks the app version and ensure the branch is clean"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :base_version,
                                       env_name: "FL_ANDROID_BETABUILD_PRECHECKS_BASE_VERSION", 
                                       description: "The version to work on", # a short description of this parameter
                                       is_string: true,
                                       optional: true), # true: verifies the input is a string, false: every kind of value),
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                        env_name: "FL_ANDROID_BETABUILD_PRECHECKS_SKIPCONFIRM",
                                        description: "Skips confirmation",
                                        is_string: false, # true: verifies the input is a string, false: every kind of value
                                        default_value: false) # the default value if the user didn't provide one
        ]
      end

      def self.output
        
      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["loremattei"]
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end