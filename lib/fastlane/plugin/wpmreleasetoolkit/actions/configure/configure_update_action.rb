require 'fastlane/action'
require 'fastlane_core/ui/ui'

require_relative '../../helper/filesystem_helper'
require_relative '../../helper/configure_helper'

module Fastlane
  module Actions
    class ConfigureUpdateAction < Action

      def self.run(params = {})
      
        prompt_to_switch_branches

        if repo_is_ahead_of_remote
          UI.user_error!("The local secrets store has changes that the remote repository doesn't.\
            Please fix this issue before continuing")
        end

        if repo_is_behind_remote
          prompt_to_update_to_most_recent_version
        end

        if configure_file_is_behind_repo
          prompt_to_update_configure_file_to_most_recent_hash
        end

        UI.success "Configuration Secrets are up to date – don't forget to commit your changes to `.configure`."
      end

      def self.prompt_to_switch_branches

        if UI.confirm("The current branch is `#{current_branch}`. Would you like to switch branches?")
          new_branch = UI.select("Select the branch you'd like to switch to: ", get_branches)
          checkout_branch(new_branch)
          update_configure_file
        end
      end

      def self.prompt_to_update_to_most_recent_version
        if UI.confirm("The current branch is #{repo_commits_behind_remote} commit(s) behind. Would you like to update it?")
          update_branch
          update_configure_file
        end
      end

      def self.prompt_to_update_configure_file_to_most_recent_hash
        if UI.confirm("The `.configure` file is #{configure_file_commits_behind_repo} commit hash(es) behind the repo. Would you like to update it?")
          update_configure_file
        end
      end

      def self.current_branch
        Fastlane::Helper::ConfigureHelper.repo_branch_name
      end

      def self.update_configure_file
        Fastlane::Helper::ConfigureHelper.update_configure_file_from_repository
      end

      def self.repo_is_ahead_of_remote
        Fastlane::Helper::ConfigureHelper.repo_is_ahead_of_remote
      end

      def self.repo_commits_behind_remote
        Fastlane::Helper::ConfigureHelper.repo_commits_behind_remote
      end

      def self.repo_is_behind_remote
        Fastlane::Helper::ConfigureHelper.repo_is_behind_remote
      end

      def self.configure_file_is_behind_repo
        Fastlane::Helper::ConfigureHelper.configure_file_is_behind_local
      end

      def self.configure_file_commits_behind_repo
        Fastlane::Helper::ConfigureHelper.configure_file_commits_behind_repo
      end

      def self.get_branches
        branches = sh("cd #{absolute_secret_store_path} && git branch -r")
        branches.split("\n")
          .map { |s| s.strip!.split("/")[1] }
          .reject { |s| s.include? "HEAD" }
      end

      ### Switch to the given branch, but don't ensure that it's up-to-date – that's for another step
      def self.checkout_branch(branch_name)
        sh("cd '#{absolute_secret_store_path}' && git checkout '#{branch_name}'")
      end

      ### Ensure that the local secrets respository is up to date
      def self.update_branch
        sh("cd '#{absolute_secret_store_path}' && git pull")
      end

      def self.absolute_secret_store_path
        Fastlane::Helper::FilesystemHelper.secret_store_dir
      end

      def self.description
        "Ensure that the local secrets repository is up to date."
      end

      def self.authors
        ["Jeremy Massel"]
      end

      def self.details
        "Ensure that the local secrets repository is up to date, and lets you test alternative branches."
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
