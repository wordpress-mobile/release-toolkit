module Fastlane
  module Actions
    class IosHotfixPrechecksAction < Action
      def self.run(params)
        UI.message "Skip confirm: #{params[:skip_confirm]}"
        UI.message ''

        require_relative '../../helper/ios/ios_version_helper.rb'
        require_relative '../../helper/ios/ios_git_helper.rb'

        # Evaluate previous tag
        new_ver = params[:version]
        prev_ver = Fastlane::Helper::Ios::VersionHelper.calc_prev_hotfix_version(new_ver)

        # Confirm
        message = "Requested Hotfix version: #{new_ver}\n"
        message << "Branching from: #{prev_ver}\n"

        if !params[:skip_confirm]
          UI.user_error!('Aborted by user request') unless UI.confirm("#{message}Do you want to continue?")
        else
          UI.message(message)
        end

        # Check tags
        UI.crash!("Version #{new_ver} already exists! Abort!") if other_action.git_tag_exists(tag: new_ver)

        UI.crash!("Version #{prev_ver} is not tagged! Can't branch. Abort!") unless other_action.git_tag_exists(tag: prev_ver)

        # Check local repo status
        other_action.ensure_git_status_clean()

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
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: 'FL_IOS_HOTFIX_PRECHECKS_VERSION',
                                       description: 'The version to work on', # a short description of this parameter
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                       env_name: 'FL_IOS_HOTFIX_PRECHECKS_SKIPCONFIRM',
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
        ['loremattei']
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
