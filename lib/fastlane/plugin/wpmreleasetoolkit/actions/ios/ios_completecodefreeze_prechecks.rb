module Fastlane
  module Actions
    class IosCompletecodefreezePrechecksAction < Action
      def self.run(params)
        UI.message "Skip confirm: #{params[:skip_confirm]}"

        require_relative '../../helper/ios/ios_version_helper'
        require_relative '../../helper/ios/ios_git_helper'
        require_relative '../../helper/git_helper'

        current_branch = Fastlane::Helper::GitHelper.current_git_branch
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
                                       type: Boolean,
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
