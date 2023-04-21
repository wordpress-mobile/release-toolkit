module Fastlane
  module Actions
    class IosCompletecodefreezePrechecksAction < Action
      def self.run(params)
        UI.message "Skip confirm: #{params[:skip_confirm]}"

        require_relative '../../helper/ios/ios_version_helper'
        require_relative '../../helper/ios/ios_git_helper'

        # We can't use `other_action.git_branch`, because it is modified by environment variables in Buildkite.
        # We need to check which branch we are actually on and not the initial branch a CI build is started from.
        # See https://docs.fastlane.tools/actions/git_branch/#git_branch
        current_branch = Fastlane::Actions.git_branch_name_using_HEAD
        UI.user_error!("Current branch - '#{current_branch}' - is not a release branch. Abort.") unless current_branch.start_with?('release/')

        version = Fastlane::Helper::Ios::VersionHelper.get_public_version
        message = "Completing code freeze for: #{version}\n"
        if params[:skip_confirm]
          UI.message(message)
        else
          UI.user_error!('Aborted by user request') unless UI.confirm("#{message}Do you want to continue?")
        end

        # Check local repo status
        other_action.ensure_git_status_clean()

        version
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Runs some prechecks before finalizing a code freeze'
      end

      def self.details
        'Runs some prechecks before finalizing a code freeze'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                       env_name: 'FL_IOS_COMPLETECODEFREEZE_PRECHECKS_SKIPCONFIRM',
                                       description: 'Skips confirmation',
                                       is_string: false, # true: verifies the input is a string, false: every kind of value
                                       default_value: false), # the default value if the user didn't provide one
        ]
      end

      def self.output
      end

      def self.return_value
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
