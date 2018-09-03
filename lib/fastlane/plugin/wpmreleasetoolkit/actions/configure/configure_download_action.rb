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

          choice = UI.select("No local secret store exists. Please choose an option: ", [
              "Install the sample data (default)",
              "Install from a git repository"
          ])

          # If they enter anything other than "2", just do the default action
          case choice
              when "2" then install_from_git_repository 
              else install_sample_data
          end
        else
          update_repository # If the repo already exists, just update it
        end
      end

      # Install the sample repository
      def self.install_sample_data

        UI.message "Installing from sample data"

        clone_repository("https://github.com/jkmassel/mobile-secrets-repository")

        UI.success "Sample Data Setup Complete"
      end

      # Attempt to install a user-provided git repository
      def self.install_from_git_repository

        UI.message "Installing from a git repository"

        ### Prompt the user for the git repo URL
        repo_url = UI.input("Git Repository URL:  ")

        clone_repository(repo_url)

        UI.success "Downloaded Data from Git Repository"
      end
     
      # Clone the git repository to `~/.mobile-secrets`
      def self.clone_repository(url)

        if sh("git clone #{url} ~/.mobile-secrets")
            UI.success "Succesfully downloaded git repository"
        else
            UI.error "Unable to download git repository"
        end
      end
      
      # Ensure the git repository at `~/.mobile-secrets` is up to date
      def self.update_repository
        sh("cd ~/.mobile-secrets && git pull")
      end

      def self.description
        "Interactively download and set up the mobile secrets respository."
      end

      def self.authors
        ["Jeremy Massel"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        "Walks the developer through setting up a `.configure` file in their project on first run.\
        On subsequent runs, updates the repository to the latest version."
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
