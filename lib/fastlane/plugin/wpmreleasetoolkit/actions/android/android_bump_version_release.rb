module Fastlane
  module Actions
    class AndroidBumpVersionReleaseAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message 'Bumping app release version...'

        require_relative '../../helper/android/android_version_helper'
        require_relative '../../helper/android/android_git_helper'

        default_branch = params[:default_branch]
        other_action.ensure_git_branch(branch: default_branch)

        # Create new configuration
        new_short_version = Fastlane::Helper::Android::VersionHelper.bump_version_release(params[:version_scheme])

        current_version = Fastlane::Helper::Android::VersionHelper.get_release_version
        current_version_alpha = Fastlane::Helper::Android::VersionHelper.get_alpha_version
        new_version_beta = Fastlane::Helper::Android::VersionHelper.calc_next_release_version(current_version, current_version_alpha)
        new_version_alpha = current_version_alpha.nil? ? nil : Fastlane::Helper::Android::VersionHelper.calc_next_alpha_version(new_version_beta, current_version_alpha)
        new_release_branch = "release/#{new_short_version}"

        vname = Fastlane::Helper::Android::VersionHelper::VERSION_NAME
        vcode = Fastlane::Helper::Android::VersionHelper::VERSION_CODE
        UI.message("Current version: #{current_version[vname]}(#{current_version[vcode]})")
        UI.message("Current alpha version: #{current_version_alpha[vname]}(#{current_version_alpha[vcode]})") unless current_version_alpha.nil?
        UI.message("New beta version: #{new_version_beta[vname]}(#{new_version_beta[vcode]})")
        UI.message("New alpha version: #{new_version_alpha[vname]}(#{new_version_alpha[vcode]})") unless current_version_alpha.nil?
        UI.message("New version: #{new_short_version}")
        UI.message("Release branch: #{new_release_branch}")

        # Update local default branch and create branch from it
        UI.message 'Creating new branch...'
        Fastlane::Helper::GitHelper.create_branch(new_release_branch, from: default_branch)
        UI.message 'Done!'

        UI.message 'Updating app version...'
        Fastlane::Helper::Android::VersionHelper.update_versions(new_version_beta, new_version_alpha)
        Fastlane::Helper::Android::GitHelper.commit_version_bump
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
          FastlaneCore::ConfigItem.new(key: :default_branch,
                                       env_name: 'FL_RELEASE_TOOLKIT_DEFAULT_BRANCH',
                                       description: 'Default branch of the repository',
                                       type: String,
                                       default_value: Fastlane::Helper::GitHelper::DEFAULT_GIT_BRANCH),
          FastlaneCore::ConfigItem.new(key: :version_scheme,
                                       env_name: 'FL_RELEASE_TOOLKIT_VERSION_SCHEME',
                                       description: 'Version scheme used by the app',
                                       type: String,
                                       default_value: 'marketing'),
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
