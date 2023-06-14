module Fastlane
  module Actions
    class IosCodefreezePrechecksAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message "Skip confirm on code freeze: #{params[:skip_confirm]}"

        require_relative '../../helper/ios/ios_version_helper'
        require_relative '../../helper/ios/ios_git_helper'

        # Checkout default branch and update
        default_branch = params[:default_branch]
        Fastlane::Helper::GitHelper.checkout_and_pull(default_branch)

        # Create versions
        current_version = Fastlane::Helper::Ios::VersionHelper.get_public_version
        current_build_version = Fastlane::Helper::Ios::VersionHelper.get_build_version
        next_version = Fastlane::Helper::Ios::VersionHelper.calc_next_release_version(current_version)

        # Ask user confirmation
        unless params[:skip_confirm] || UI.confirm("Building a new release branch starting from #{default_branch}.\nCurrent version is #{current_version} (#{current_build_version}).\nAfter codefreeze the new version will be: #{next_version}.\nDo you want to continue?")
          UI.user_error!('Aborted by user request')
        end

        # Check local repo status
        other_action.ensure_git_status_clean

        # Return the current version
        current_version
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
                                       env_name: 'FL_IOS_CODEFREEZE_PRECHECKS_SKIPCONFIRM',
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
        [:ios, :mac].include?(platform)
      end
    end
  end
end
