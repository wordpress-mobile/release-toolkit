require 'fastlane/action'
require 'fastlane_core/ui/ui'
require 'fileutils'

module Fastlane
  module Actions
    class ConfigureDownloadAction < Action
      def self.run(params = {})
        UI.message 'Running Configure Download'

        # If the `~/.mobile-secrets` repository doesn't exist
        unless File.directory?("#{secrets_dir}")
          UI.user_error!("The local secrets store does not exist. Please clone it to #{secrets_dir} before continuing.")
        else
          update_repository # If the repo already exists, just update it
        end
      end

      # Ensure the git repository at `~/.mobile-secrets` is up to date.
      # If the secrets repo is in a detached HEAD state, skip the pull,
      # since it will fail.
      def self.update_repository
        secrets_repo_branch = Fastlane::Helper::ConfigureHelper.repo_branch_name

        sh("cd #{secrets_dir} && git pull") unless secrets_repo_branch == nil
      end

      def self.secrets_dir
        Fastlane::Helper::FilesystemHelper.secret_store_dir
      end

      def self.description
        'Updates the mobile secrets.'
      end

      def self.authors
        ['Jeremy Massel']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        'Pulls down the latest remote changes to the ~/.mobile-secrets repository.'
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
