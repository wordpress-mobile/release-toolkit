module Fastlane
  module Actions
    class AndroidHotfixPrechecksAction < Action
      def self.run(params)
        UI.message "Skip confirm: #{params[:skip_confirm]}"
        UI.message ''

        require_relative '../../helper/android/android_version_helper'
        require_relative '../../helper/android/android_git_helper'

        # Evaluate previous tag
        new_ver = params[:version_name]
        prev_ver = Fastlane::Helper::Android::VersionHelper.calc_prev_hotfix_version_name(new_ver)

        # Confirm
        message = "Requested Hotfix version: #{new_ver}\n"
        message << "Branching from tag: #{prev_ver}\n"

        if params[:skip_confirm]
          UI.message(message)
        else
          UI.user_error!('Aborted by user request') unless UI.confirm("#{message}Do you want to continue?")
        end

        # Check tags
        UI.crash!("Version #{new_ver} already exists! Abort!") if other_action.git_tag_exists(tag: new_ver)

        UI.crash!("Version #{prev_ver} is not tagged! Can't branch. Abort!") unless other_action.git_tag_exists(tag: prev_ver)

        # Check local repo status
        other_action.ensure_git_status_clean

        # Return the current version
        prev_ver
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Runs some prechecks before preparing for a new hotfix'
      end

      def self.details
        'Checks out a new branch from a tag and updates tags'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version_name,
                                       env_name: 'FL_ANDROID_HOTFIX_PRECHECKS_VERSION',
                                       description: 'The hotfix version number to create',
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                       env_name: 'FL_ANDROID_HOTFIX_PRECHECKS_SKIPCONFIRM',
                                       description: 'Skips confirmation',
                                       is_string: false, # Boolean
                                       default_value: false),
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
        platform == :android
      end
    end
  end
end
