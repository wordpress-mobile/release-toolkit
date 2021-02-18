require 'fastlane/action'
require 'fastlane_core/ui/ui'
require 'fileutils'
require 'diffy'

require_relative '../../helper/filesystem_helper'
require_relative '../../helper/configure_helper'

module Fastlane
  module Actions
    class ConfigureApplyAction < Action
      def self.run(params = {})
        # Preflight
        UI.user_error!('Decryption key could not be found') if Fastlane::Helper::ConfigureHelper.encryption_key.nil?

        # Checkout the right commit hash etc. before applying the configuration
        prepare_repository do
          # Copy/decrypt the files
          files_to_copy.each do |file_reference|
            apply_file(file_reference, params[:force])
          end
        end
        UI.success 'Applied configuration'
      end

      def self.prepare_repository
        secrets_respository_exists = File.exist?(repository_path)

        # If the secrets repo doesn't exist, just run the block
        unless secrets_respository_exists
          # Run the provided block, and return
          yield
          return
        end

        ### Make sure secrets repo is at the proper hash as specified in .configure.
        repo_hash = Fastlane::Helper::ConfigureHelper.repo_commit_hash
        file_hash = Fastlane::Helper::ConfigureHelper.configure_file_commit_hash

        ### Get the ref to restore the repo to
        original_repo_ref = Fastlane::Helper::ConfigureHelper.repo_branch_name
        original_repo_ref = repo_hash if original_repo_ref.nil?

        other_action.sh(command: "cd #{repository_path} && git fetch && git checkout #{file_hash}", log: false) unless repo_hash == file_hash

        # Run the provided block
        yield

        ### Restore secrets repo to original branch.  If it was originally in a
        ### detached HEAD state, we need to use the hash since there's no branch name.
        other_action.sh(command: "cd #{repository_path} && git checkout #{original_repo_ref}", log: false)
      end

      ### Check with the user whether we should overwrite the file, if it exists
      ###
      def self.apply_file(file_reference, force)
        # If the file doesn't exist or force is true, we don't need to confirm
        if !File.file?(file_reference.destination) || force
          file_reference.apply
          return # Don't continue if we were able to copy the file without conflict
        end

        unless file_reference.needs_apply?
          return # Nothing to do if the files are identical
        end

        puts Diffy::Diff.new(file_reference.destination_contents, file_reference.source_contents) if UI.confirm("#{file_reference.destination} has changes that need to be merged. Would you like to see a diff?")

        if UI.confirm("Would you like to make a backup of #{file_reference.destination}?")
          extension = File.extname(file_reference.destination)
          base = File.basename(Pathname.new(file_reference.destination), extension)

          date_string = Time.now.strftime('%m-%d-%Y--%H-%M-%S')

          backup_path = base
                        .concat('-') # Handy-dandy separator
                        .concat(date_string) # date string to allow multiple backups
                        .concat(extension) # and the original file extension
                        .concat('.bak') # add the .bak file extension - easier to .gitignore

          # Create the destination directory if it doesn't exist
          FileUtils.mkdir_p(Pathname.new(file_reference.destination).dirname)
          FileUtils.cp(file_reference.destination, backup_path)
        end

        if UI.confirm("Would you like to overwrite #{file_reference.destination}?")
          file_reference.apply
        else
          UI.message "Skipping #{file_reference.destination}"
        end
      end

      def self.repository_path
        Fastlane::Helper::FilesystemHelper.secret_store_dir
      end

      def self.files_to_copy
        Fastlane::Helper::ConfigureHelper.files_to_copy
      end

      def self.absolute_project_path(relative_path)
        Fastlane::Helper::FilesystemHelper.absolute_project_path(relative_path)
      end

      def self.absolute_secret_store_path(relative_path)
        Fastlane::Helper::FilesystemHelper.absolute_secret_store_path(relative_path)
      end

      def self.description
        'Copy files specified in `.config` from the secrets repository to the project. Specify force:true to avoid confirmation'
      end

      def self.authors
        ['Jeremy Massel']
      end

      def self.details
        'Copy files specified in `.config` from the secrets repository to the project. Specify force:true to avoid confirmation'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :force,
                                       env_name: 'FORCE_OVERWRITE',
                                       description: 'Overwrite copied files without confirmation',
                                       optional: true,
                                       default_value: false,
                                       is_string: false)
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
