require 'fastlane/action'
require 'fastlane_core/ui/ui'
require 'fileutils'

module Fastlane
  module Actions
    class ConfigureDownloadAction < Action
      def self.run(params = {})

        UI.message "Running Configure Download"

        # If the `~/.mobile-secrets` repository doesn't exist
        unless File.directory?("#{Dir.home}/.mobile-secrets")
            UI.user_error!("The local secrets store does not exist. Please clone it to ~/.mobile-secrets before continuing.")
        else
          update_repository # If the repo already exists, just update it
        end
      end
      
      # Ensure the git repository at `~/.mobile-secrets` is up to date
      def self.update_repository
        sh("cd ~/.mobile-secrets && git pull")
      end

      def self.description
        "Updates the mobile secrets."
      end

      def self.authors
        ["Jeremy Massel"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        "Pulls down the latest remote changes to the ~/.mobile-secrets repository."
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
