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

        prompt_to_update_to_most_recent_version if repo_is_behind_remote

        if configure_file_is_behind_repo
          prompt_to_update_configure_file_to_most_recent_hash
        else
          # Update configure file even if already update to date
          # This ensures the file format is up to date
          update_configure_file
        end

        # If there is no encryption key for the project, generate one
        if Fastlane::Helper::ConfigureHelper.project_encryption_key.nil?
          # If the user chose not to update the repo but there is no encryption key, throw an error
          UI.user_error!('The local secrets behind the remote but it is missing a keys.json entry for this project. Please update it to the latest commit.') if repo_is_behind_remote
          Fastlane::Helper::ConfigureHelper.update_project_encryption_key
          # Update the configure file to the new hash
          update_configure_file
        end

        Fastlane::Helper::ConfigureHelper.files_to_copy.each do |file_reference|
          file_reference.update
        end

        UI.success "Configuration Secrets are up to date – don't forget to commit your changes to `.configure`."

        # Apply the changes that are now in the .configure file
        other_action.configure_apply
      end

      def self.prompt_to_switch_branches
        branch_name_to_display = current_branch.nil? ? current_hash : current_branch
        if UI.confirm("The current branch is `#{branch_name_to_display}`. Would you like to switch branches?")
          new_branch = UI.select("Select the branch you'd like to switch to: ", get_branches)
          checkout_branch(new_branch)
          update_configure_file
        else
          UI.user_error!('The local secrets store is in a deatched HEAD state.  Please check out a branch and try again.') if current_branch.nil?
        end
      end

      def self.prompt_to_update_to_most_recent_version
        if UI.confirm("The current branch is #{repo_commits_behind_remote} commit(s) behind. Would you like to update it?")
          update_branch
          update_configure_file
        end
      end

      def self.prompt_to_update_configure_file_to_most_recent_hash
        update_configure_file if UI.confirm("The `.configure` file is #{configure_file_commits_behind_repo} commit hash(es) behind the repo. Would you like to update it?")
      end

      def self.current_branch
        Fastlane::Helper::ConfigureHelper.repo_branch_name
      end

      def self.current_hash
        Fastlane::Helper::ConfigureHelper.repo_commit_hash
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
                .map { |s| s.strip!.split('/')[1] }
                .reject { |s| s.include? 'HEAD' }
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
        'Ensure that the local secrets repository is up to date.'
      end

      def self.authors
        ['Automattic']
      end

      def self.details
        'Ensure that the local secrets repository is up to date, and lets you test alternative branches.'
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
