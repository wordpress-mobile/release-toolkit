module Fastlane
  module Actions
    class AndroidBumpVersionHotfixAction < Action
      def self.run(params)
        UI.message 'Bumping app release version for hotfix...'

        require_relative '../../helper/android/android_git_helper'
        Fastlane::Helper::GitHelper.create_branch("release/#{params[:version_name]}", from: params[:previous_version_name])

        app = params[:app]

        current_version = Fastlane::Helper::Android::VersionHelper.get_release_version(product_name: app)
        new_version = Fastlane::Helper::Android::VersionHelper.calc_next_hotfix_version(params[:version_name], params[:version_code]) # NOTE: this just puts the name/code values in a tuple, unchanged (no actual calc/bumping)
        new_release_branch = "release/#{params[:version_name]}"

        name_key = Fastlane::Helper::Android::VersionHelper::VERSION_NAME
        code_key = Fastlane::Helper::Android::VersionHelper::VERSION_CODE
        UI.message("Current version [#{app}]: #{current_version[name_key]} (#{current_version[code_key]})")
        UI.message("New hotfix version[#{app}]: #{new_version[name_key]} (#{new_version[code_key]})")
        UI.message("Release branch: #{new_release_branch}")

        UI.message 'Updating app version...'
        Fastlane::Helper::Android::VersionHelper.update_versions(app, new_version, nil)
        UI.message 'Done!'

        Fastlane::Helper::Android::GitHelper.commit_version_bump()

        UI.message 'Done.'
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Bumps the version of the app for a new beta.'
      end

      def self.details
        'Bumps the version of the app for a new beta.'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version_name,
                                       env_name: 'FL_ANDROID_BUMP_VERSION_HOTFIX_VERSION',
                                       description: 'The version name for the hotfix',
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :version_code,
                                       env_name: 'FL_ANDROID_BUMP_VERSION_HOTFIX_CODE',
                                       description: 'The version code for the hotfix'),
          FastlaneCore::ConfigItem.new(key: :previous_version_name,
                                       env_name: 'FL_ANDROID_BUMP_VERSION_HOTFIX_PREVIOUS_VERSION',
                                       description: 'The version to branch from',
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :app,
                                       env_name: 'PROJECT_NAME',
                                       description: 'The name of the app to get the release version for',
                                       is_string: true),
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
