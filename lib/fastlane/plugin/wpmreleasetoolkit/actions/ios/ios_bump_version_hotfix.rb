module Fastlane
  module Actions
    class IosBumpVersionHotfixAction < Action
      def self.run(params)
        UI.message 'Bumping app release version for hotfix...'

        require_relative '../../helper/ios/ios_git_helper'
        Fastlane::Helper::GitHelper.create_branch("release/#{params[:version]}", from: params[:previous_version])
        create_config(params[:previous_version], params[:version])
        show_config()

        update_deliverfile = params[:skip_deliver] == false
        if update_deliverfile
          UI.message 'Updating Fastlane deliver file...'
          Fastlane::Helper::Ios::VersionHelper.update_fastlane_deliver(@new_short_version)
          UI.message 'Done!'
        end

        UI.message 'Updating XcConfig...'
        Fastlane::Helper::Ios::VersionHelper.update_xc_configs(@new_version, @new_short_version, @new_version_internal)
        UI.message 'Done!'

        Fastlane::Helper::Ios::GitHelper.commit_version_bump(include_deliverfile: update_deliverfile, include_metadata: false)

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
          FastlaneCore::ConfigItem.new(
            key: :version,
            env_name: 'FL_IOS_BUMP_VERSION_HOTFIX_VERSION',
            description: 'The version of the hotfix',
            is_string: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :previous_version,
            env_name: 'FL_IOS_BUMP_VERSION_HOTFIX_PREVIOUS_VERSION',
            description: 'The version to branch from',
            is_string: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :skip_deliver,
            env_name: 'FL_IOS_BUMP_VERSION_HOTFIX_SKIP_DELIVER',
            description: 'Skips Deliverfile key update',
            is_string: false, # Boolean parameter
            optional: true,
            # Don't skip the Deliverfile by default. At the time of writing, 2 out of 3 consumers
            # still have a Deliverfile.
            default_value: false
          ),
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
        [:ios, :mac.include?(platform)
      end

      private

      def self.create_config(previous_version, new_short_version)
        @current_version = previous_version
        @current_version_internal = Fastlane::Helper::Ios::VersionHelper.get_internal_version() unless ENV['INTERNAL_CONFIG_FILE'].nil?
        @new_version = "#{new_short_version}.0"
        @new_version_internal = Fastlane::Helper::Ios::VersionHelper.create_internal_version(@new_version) unless ENV['INTERNAL_CONFIG_FILE'].nil?
        @new_short_version = new_short_version
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
