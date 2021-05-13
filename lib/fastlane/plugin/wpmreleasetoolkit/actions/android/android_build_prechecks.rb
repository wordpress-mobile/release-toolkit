module Fastlane
  module Actions
    class AndroidBuildPrechecksAction < Action
      def self.run(params)
        require_relative '../../helper/android/android_version_helper.rb'
        require_relative '../../helper/git_helper.rb'

        UI.user_error!("Can't build beta and final at the same time!") if params[:final] && params[:beta]

        Fastlane::Helper::GitHelper.ensure_on_branch!('release') unless other_action.is_ci()

        app = ENV['RELEASE_FLAVOR'].nil? ? params[:app]: ENV['RELEASE_FLAVOR']
        message = ''
        beta_version = Fastlane::Helper::Android::VersionHelper.get_release_version(app) unless !params[:beta] && !params[:final]
        alpha_version = Fastlane::Helper::Android::VersionHelper.get_alpha_version(app) if params[:alpha]

        UI.user_error!("Can't build a final release out of this branch because it's configured as a beta release!") if params[:final] && Fastlane::Helper::Android::VersionHelper.is_beta_version?(beta_version)

        message << "[#{app}] Building version #{beta_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}(#{beta_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}) (for upload to Release Channel)\n" if params[:final]
        message << "[#{app}] Building version #{beta_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}(#{beta_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}) (for upload to Beta Channel)\n" if params[:beta]
        message << "[#{app}] Building version #{alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}(#{alpha_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]}) (for upload to Alpha Channel)\n" if params[:alpha]

        if !params[:skip_confirm]
          UI.user_error!('Aborted by user request') unless UI.confirm("#{message}Do you want to continue?")
        else
          UI.message(message)
        end

        # Check local repo status
        other_action.ensure_git_status_clean() unless other_action.is_ci()
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Runs some prechecks before the build'
      end

      def self.details
        'Runs some prechecks before the build'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :skip_confirm,
                                       env_name: 'FL_ANDROID_BUILD_PRECHECKS_SKIP_CONFIRM',
                                       description: 'True to avoid the system ask for confirmation',
                                       is_string: false,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :alpha,
                                       env_name: 'FL_ANDROID_BUILD_PRECHECKS_ALPHA_BUILD',
                                       description: 'True if this is for an alpha build',
                                       is_string: false,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :beta,
                                       env_name: 'FL_ANDROID_BUILD_PRECHECKS_BETA_BUILD',
                                       description: 'True if this is for a beta build',
                                       is_string: false,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :final,
                                       env_name: 'FL_ANDROID_BUILD_PRECHECKS_FINAL_BUILD',
                                       description: 'True if this is for a final build',
                                       is_string: false,
                                       default_value: false),
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
