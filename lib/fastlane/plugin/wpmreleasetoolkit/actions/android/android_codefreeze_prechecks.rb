module Fastlane
  module Actions
    class AndroidCodefreezePrechecksAction < Action
      VERSION_RELEASE = 'release'
      VERSION_ALPHA = 'alpha'

      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message "Skip confirm on code freeze: #{params[:skip_confirm]}"

        require_relative '../../helper/android/android_version_helper.rb'
        require_relative '../../helper/android/android_git_helper.rb'

        # Checkout develop and update
        Fastlane::Helper::GitHelper.checkout_and_pull('develop')

        app = ENV['RELEASE_FLAVOR'].nil? ? params[:app] : ENV['RELEASE_FLAVOR']

        # Create versions
        current_version = Fastlane::Helper::Android::VersionHelper.get_release_version(app)
        current_alpha_version = Fastlane::Helper::Android::VersionHelper.get_alpha_version(app)
        next_version = Fastlane::Helper::Android::VersionHelper.calc_next_release_version(current_version, current_alpha_version)
        next_alpha_version = current_alpha_version.nil? ? nil : Fastlane::Helper::Android::VersionHelper.calc_next_alpha_version(next_version, current_alpha_version)

        no_alpha_version_message = "No alpha version configured. If you wish to configure an alpha version please update version.properties to include an alpha key for this flavor\n"
        # Ask user confirmation
        unless params[:skip_confirm]
          confirm_message = "[#{app}]Building a new release branch starting from develop.\nCurrent version is #{current_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]} (#{current_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}).\n"
          confirm_message += current_alpha_version.nil? ? no_alpha_version_message : "Current Alpha version is #{current_alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]} (#{current_alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}).\n"
          confirm_message += "After codefreeze the new version will be: #{next_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]} (#{next_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}).\n"
          confirm_message += current_alpha_version.nil? ? '' : "After codefreeze the new Alpha will be: #{next_alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]} (#{next_alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}).\n"
          confirm_message += 'Do you want to continue?'
          UI.user_error!('Aborted by user request') unless UI.confirm(confirm_message)
        end

        # Check local repo status
        other_action.ensure_git_status_clean()

        # Return the current version
        Fastlane::Helper::Android::VersionHelper.get_public_version(app)
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
          FastlaneCore::ConfigItem.new(key: :app,
                                       env_name: 'APP',
                                       description: 'The app to get the release version for',
                                       is_string: true, # true: verifies the input is a string, false: every kind of value
                                       default_value: 'wordpress'), # the default value if the user didn't provide one
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
