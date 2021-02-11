require 'fastlane/action'
require 'fastlane_core/ui/ui'
require 'fileutils'
require 'git'

require_relative '../../helper/filesystem_helper'
require_relative '../../helper/configure_helper'

module Fastlane
  module Actions
    class ConfigureSetupAction < Action
      def self.run(params = {})

        # Check to see if the local secret storage is set up at ~/.mobile-secrets.
        unless File.directory?(repository_path)
          UI.user_error!('The local secrets store does not exist. Please clone it to ~/.mobile-secrets before continuing.')
        end

        # Checks to see if .configure exists. If so, exit – there’s no need to continue as everything is set up.
        if configuration_file_exists
          UI.success 'Configure file exists – exiting.'
          return
        end

        # The mobile secrets repo must be up to date in order to generate and save the encryption key
        if Fastlane::Helper::ConfigureHelper.repo_is_behind_remote
          prompt_to_update_to_most_recent_version
        end

        # Generate an encryption key for the new project, if needed
        Fastlane::Helper::ConfigureHelper.update_project_encryption_key if Fastlane::Helper::ConfigureHelper.project_encryption_key.nil?

        # Write out the `.configure` file.
        Fastlane::Helper::ConfigureHelper.update_configure_file_from_repository

        # Walk the user through adding files to copy to the `.configure` file.
        ConfigureAddFilesToCopyAction.run

        # Copy the files we just walked the user through setting up.
        ConfigureApplyAction.run

        UI.success 'Created .configure file'
      end

      def self.prompt_to_update_to_most_recent_version
        if UI.confirm("The current branch is #{Fastlane::Helper::ConfigureHelper.repo_commits_behind_remote} commit(s) behind. It must be updated to complete the setup. Would you like to continue?")
          update_branch
        else
          UI.user_error!('Cannot complete setup when the repo is not up to date.')
        end
      end

      ### Ensure that the local secrets respository is up to date
      def self.update_branch
        sh("cd '#{Fastlane::Helper::FilesystemHelper.secret_store_dir}' && git pull")
      end

      def self.configuration_file_exists
        Fastlane::Helper::ConfigureHelper.configuration_path_exists
      end

      def self.repository_path
        Fastlane::Helper::FilesystemHelper.secret_store_dir
      end

      def self.description
        'Set up the .configure file'
      end

      def self.authors
        ['Jeremy Massel']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        'Interactively walks the user through setting up the `.configure` file. Assumes the ~/.mobile-secrets directory exists'
      end

      def self.available_options
        []
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
