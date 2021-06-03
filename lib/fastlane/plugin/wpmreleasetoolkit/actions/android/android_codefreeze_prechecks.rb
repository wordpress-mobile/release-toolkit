module Fastlane
  module Actions
    class AndroidCodefreezePrechecksAction < Action
      VERSION_RELEASE = 'release'
      VERSION_ALPHA = 'alpha'

      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message "Skip confirm on code freeze: #{params[:skip_confirm]}"

        require_relative '../../helper/android/android_version_helper'
        require_relative '../../helper/android/android_git_helper'

        # Checkout develop and update
        Fastlane::Helper::GitHelper.checkout_and_pull('develop')

        # Create versions
        current_version = Fastlane::Helper::Android::VersionHelper.get_release_version
        current_alpha_version = Fastlane::Helper::Android::VersionHelper.get_alpha_version
        next_version = Fastlane::Helper::Android::VersionHelper.calc_next_release_version(current_version, current_alpha_version)
        next_alpha_version = ENV['HAS_ALPHA_VERSION'].nil? ? nil : Fastlane::Helper::Android::VersionHelper.calc_next_alpha_version(next_version, current_alpha_version)

        # Ask user confirmation
        unless params[:skip_confirm]
          confirm_message = "Building a new release branch starting from develop.\nCurrent version is #{current_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]} (#{current_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}).\n"
          confirm_message += ENV['HAS_ALPHA_VERSION'].nil? ? "No alpha version configured.\n" : "Current Alpha version is #{current_alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]} (#{current_alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}).\n"
          confirm_message += "After codefreeze the new version will be: #{next_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]} (#{next_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}).\n"
          confirm_message += ENV['HAS_ALPHA_VERSION'].nil? ? '' : "After codefreeze the new Alpha will be: #{next_alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]} (#{next_alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}).\n"
          confirm_message += 'Do you want to continue?'
          UI.user_error!('Aborted by user request') unless UI.confirm(confirm_message)
        end

        # Check local repo status
        other_action.ensure_git_status_clean()

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
        'Updates the develop branch, checks the app version and ensure the branch is clean'
      end

      def self.available_options
        # Define all options your action supports.
        [
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                       env_name: 'FL_ANDROID_CODEFREEZE_PRECHECKS_SKIPCONFIRM',
                                       description: 'Skips confirmation before codefreeze',
                                       is_string: false, # true: verifies the input is a string, false: every kind of value
                                       default_value: false), # the default value if the user didn't provide one
        ]
      end

      def self.output
      end

      def self.return_value
        'Version of the app before code freeze'
      end

      def self.authors
        ['loremattei']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
