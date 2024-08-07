module Fastlane
  module Actions
    class IosBumpVersionBetaAction < Action
      def self.run(params)
        UI.message 'Bumping app release version...'

        require_relative '../../helper/ios/ios_git_helper'
        require_relative '../../helper/ios/ios_version_helper'

        # Verify that the current branch is a release branch. Notice that `ensure_git_branch` expects a RegEx parameter
        ensure_git_branch(branch: '^release/')
        create_config
        show_config

        UI.message 'Updating XcConfig...'
        Fastlane::Helper::Ios::VersionHelper.update_xc_configs(@new_beta_version, @short_version, @new_internal_version)
        UI.message 'Done!'

        Fastlane::Helper::Ios::GitHelper.commit_version_bump
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Bumps the version of the app for a new beta'
      end

      def self.details
        'Bumps the version of the app for a new beta'
      end

      def self.available_options
      end

      def self.output
      end

      def self.return_value
      end

      def self.category
        :deprecated
      end

      def self.deprecated_notes
        'This action is deprecated and will be removed in the next major version update of the Release Toolkit. Please use the formatters and calculators in the Versioning module to automate version changes.'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        %i[ios mac].include?(platform)
      end

      def self.create_config
        @current_version = Fastlane::Helper::Ios::VersionHelper.get_build_version
        @current_version_internal = Fastlane::Helper::Ios::VersionHelper.get_internal_version unless ENV['INTERNAL_CONFIG_FILE'].nil?
        @new_internal_version = Fastlane::Helper::Ios::VersionHelper.create_internal_version(@current_version) unless ENV['INTERNAL_CONFIG_FILE'].nil?
        @new_beta_version = Fastlane::Helper::Ios::VersionHelper.calc_next_build_version(@current_version)
        @short_version = Fastlane::Helper::Ios::VersionHelper.get_short_version_string(@new_beta_version)
      end

      def self.show_config
        UI.message("Current build version: #{@current_version}")
        UI.message("Current internal version: #{@current_version_internal}") unless ENV['INTERNAL_CONFIG_FILE'].nil?
        UI.message("New beta version: #{@new_beta_version}")
        UI.message("New internal version: #{@new_internal_version}") unless ENV['INTERNAL_CONFIG_FILE'].nil?
      end
    end
  end
end
