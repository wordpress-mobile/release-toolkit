module Fastlane
  module Actions
    class AndroidCodefreezePrechecksAction < Action
      VERSION_RELEASE = 'release'.freeze
      VERSION_ALPHA = 'alpha'.freeze

      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message "Skip confirm on code freeze: #{params[:skip_confirm]}"

        require_relative '../../helper/android/android_version_helper'
        require_relative '../../helper/android/android_git_helper'

        # Checkout default branch and update
        default_branch = params[:default_branch]
        Fastlane::Helper::GitHelper.checkout_and_pull(default_branch)

        # Create versions
        current_version = Fastlane::Helper::Android::VersionHelper.get_release_version
        current_alpha_version = Fastlane::Helper::Android::VersionHelper.get_alpha_version
        next_version = Fastlane::Helper::Android::VersionHelper.calc_next_release_version(current_version, current_alpha_version)
        next_alpha_version = current_alpha_version.nil? ? nil : Fastlane::Helper::Android::VersionHelper.calc_next_alpha_version(next_version, current_alpha_version)

        no_alpha_version_message = "No alpha version configured. If you wish to configure an alpha version please update version.properties to include an alpha key for this app\n"
        # Ask user confirmation
        unless params[:skip_confirm]
          confirm_message = "Building a new release branch starting from #{default_branch}.\nCurrent version is #{current_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]} (#{current_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}).\n"
          confirm_message += current_alpha_version.nil? ? no_alpha_version_message : "Current Alpha version is #{current_alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]} (#{current_alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}).\n"
          confirm_message += "After codefreeze the new version will be: #{next_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]} (#{next_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}).\n"
          confirm_message += current_alpha_version.nil? ? '' : "After codefreeze the new Alpha will be: #{next_alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]} (#{next_alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}).\n"
          confirm_message += 'Do you want to continue?'
          UI.user_error!('Aborted by user request') unless UI.confirm(confirm_message)
        end

        # Check local repo status
        other_action.ensure_git_status_clean

        # Return the current version
        Fastlane::Helper::Android::VersionHelper.get_public_version
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Runs some prechecks before code freeze'
      end

      def self.details
        'Updates the default branch, checks the app version and ensure the branch is clean'
      end

      def self.available_options
        # Define all options your action supports.
        [
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                       env_name: 'FL_ANDROID_CODEFREEZE_PRECHECKS_SKIPCONFIRM',
                                       description: 'Skips confirmation before codefreeze',
                                       type: Boolean,
                                       default_value: false), # the default value if the user didn't provide one
          FastlaneCore::ConfigItem.new(key: :default_branch,
                                       env_name: 'FL_RELEASE_TOOLKIT_DEFAULT_BRANCH',
                                       description: 'Default branch of the repository',
                                       type: String,
                                       default_value: Fastlane::Helper::GitHelper::DEFAULT_GIT_BRANCH),
        ]
      end

      def self.output
      end

      def self.return_value
        'Version of the app before code freeze'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
