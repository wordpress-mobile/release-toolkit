module Fastlane
  module Actions
    class AndroidBumpVersionHotfixAction < Action
      def self.run(params)
        UI.message 'Bumping app release version for hotfix...'

        require_relative '../../helper/android/android_git_helper'
        Fastlane::Helper::GitHelper.create_branch("release/#{params[:version_name]}", from: params[:previous_version_name])

        app = params[:app]

        current_version = Fastlane::Helper::Android::VersionHelper.get_release_version(product_name: app)
        current_version_alpha = Fastlane::Helper::Android::VersionHelper.get_alpha_version(app)
        new_version = Fastlane::Helper::Android::VersionHelper.calc_next_hotfix_version(params[:version_name], params[:version_code])
        new_short_version = new_version_name
        new_release_branch = "release/#{new_short_version}"

        UI.message("Current version[#{app}]: #{current_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}(#{current_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]})")
        UI.message("New hotfix version[#{app}]: #{new_version[Fastlane::Helper::Android::VersionHelper::VERSION_NAME]}(#{new_version[Fastlane::Helper::Android::VersionHelper::VERSION_CODE]})")
        UI.message("Release branch: #{new_release_branch}")

        UI.message 'Updating app version...'
        Fastlane::Helper::Android::VersionHelper.update_versions(app, new_version, current_version_alpha)
        UI.message 'Done!'

        Fastlane::Helper::Android::GitHelper.commit_version_bump()

        UI.message 'Done.'
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Bumps the version of the app for a new beta. Requires the `updateVersionProperties` gradle task to update the keys if you are using a `version.properties` file.'
      end

      def self.details
        'Bumps the version of the app for a new beta. Requires the `updateVersionProperties` gradle task to update the keys if you are using a `version.properties` file.'
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :version_name,
                                       env_name: 'FL_ANDROID_BUMP_VERSION_HOTFIX_VERSION',
                                       description: 'The version of the hotfix',
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :version_code,
                                       env_name: 'FL_ANDROID_BUMP_VERSION_HOTFIX_CODE',
                                       description: 'The version of the hotfix'),
          FastlaneCore::ConfigItem.new(key: :previous_version_name,
                                       env_name: 'FL_ANDROID_BUMP_VERSION_HOTFIX_PREVIOUS_VERSION',
                                       description: 'The version to branch from',
                                       is_string: true), # the default value if the user didn't provide one
          FastlaneCore::ConfigItem.new(key: :app,
                                       env_name: 'PROJECT_NAME',
                                       description: 'The name of the app to get the release version for',
                                       is_string: true), # true: verifies the input is a string, false: every kind of value
        ]
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
