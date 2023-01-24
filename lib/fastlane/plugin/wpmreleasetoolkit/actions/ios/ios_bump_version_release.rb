module Fastlane
  module Actions
    class IosBumpVersionReleaseAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message 'Bumping app release version...'

        require_relative '../../helper/ios/ios_version_helper'
        require_relative '../../helper/ios/ios_git_helper'

        default_branch = params[:default_branch]
        other_action.ensure_git_branch(branch: default_branch)

        # Create new configuration
        @new_version = Fastlane::Helper::Ios::VersionHelper.bump_version_release
        create_config
        show_config

        # Update local default branch and create branch from it
        Fastlane::Helper::GitHelper.checkout_and_pull(default_branch)
        Fastlane::Helper::GitHelper.create_branch(@new_release_branch, from: default_branch)
        UI.message 'Done!'

        UI.message 'Updating Fastlane deliver file...' unless params[:skip_deliver]
        Fastlane::Helper::Ios::VersionHelper.update_fastlane_deliver(@new_short_version) unless params[:skip_deliver]
        UI.message 'Done!' unless params[:skip_deliver]

        UI.message 'Updating XcConfig...'
        Fastlane::Helper::Ios::VersionHelper.update_xc_configs(@new_version, @new_short_version, @new_version_internal)
        UI.message 'Done!'

        Fastlane::Helper::Ios::GitHelper.commit_version_bump(
          include_deliverfile: !params[:skip_deliver]
        )

        UI.message 'Done.'
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Bumps the version of the app and creates the new release branch'
      end

      def self.details
        'Bumps the version of the app and creates the new release branch'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :skip_deliver,
                                       env_name: 'FL_IOS_CODEFREEZE_BUMP_SKIPDELIVER',
                                       description: 'Skips Deliver key update',
                                       type: Boolean,
                                       default_value: false),
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
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.create_config
        @current_version = Fastlane::Helper::Ios::VersionHelper.get_build_version
        @current_version_internal = Fastlane::Helper::Ios::VersionHelper.get_internal_version unless ENV['INTERNAL_CONFIG_FILE'].nil?
        @new_version_internal = Fastlane::Helper::Ios::VersionHelper.create_internal_version(@new_version) unless ENV['INTERNAL_CONFIG_FILE'].nil?
        @new_short_version = Fastlane::Helper::Ios::VersionHelper.get_short_version_string(@new_version)
        @new_release_branch = "release/#{@new_short_version}"
      end

      def self.show_config
        UI.message("Current build version: #{@current_version}")
        UI.message("Current internal version: #{@current_version_internal}") unless ENV['INTERNAL_CONFIG_FILE'].nil?
        UI.message("New build version: #{@new_version}")
        UI.message("New internal version: #{@new_version_internal}") unless ENV['INTERNAL_CONFIG_FILE'].nil?
        UI.message("New short version: #{@new_short_version}")
        UI.message("Release branch: #{@new_release_branch}")
      end
    end
  end
end
