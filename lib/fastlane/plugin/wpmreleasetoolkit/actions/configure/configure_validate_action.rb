require 'fastlane/action'
require 'fastlane_core/ui/ui'

require_relative '../../helper/filesystem_helper'
require_relative '../../helper/configure_helper'

module Fastlane
  module Actions
    class ConfigureValidateAction < Action

      def self.run(params = {})
        # Update the repository to get the latest version of the configuration secrets – that's
        # how we'll know if we're behind in subsequent validations
        ConfigureDownloadAction::run

        validate_that_branches_match

        validate_that_hashes_match

        validate_that_secrets_repo_is_clean

        validate_that_all_copied_files_match

        UI.success "Configuration is valid"
      end

      ###
      #         VALIDATION RULES
      ###

      ### Validate that the branch specified in .configure matches the branch
      ### checked out in ~/.mobile-secrets.
      def self.validate_that_branches_match

        repo_branch_name = Fastlane::Helper::ConfigureHelper.repo_branch_name
        file_branch_name = Fastlane::Helper::ConfigureHelper.configure_file_branch_name

        unless repo_branch_name == file_branch_name

          UI.user_error!([
            "The branch specified in `.configure` is not the currently checked out branch in the secrets repository.",
            "To fix this issue, switch back to the `#{file_branch_name}` branch in the mobile secrets repository.",
          ].join("\n"))
        end
      end

      ### Validate that the commit hash in the .configure file matches the
      ### latest commit hash in ~/.mobile-secrets.
      def self.validate_that_hashes_match
        repo_hash = Fastlane::Helper::ConfigureHelper.repo_commit_hash
        file_hash = Fastlane::Helper::ConfigureHelper.configure_file_commit_hash

        unless repo_hash == file_hash
            UI.user_error!("The `.configure` file is out of date. Please update it before continuing.")
        end
      end

      ### Validate that the secrets repo doesn't have any local changes
      def self.validate_that_secrets_repo_is_clean
        unless Fastlane::Helper::ConfigureHelper.repo_has_changes
            UI.user_error!("The secrets repository has uncommitted changes. Please commit or discard them before continuing.")
        end
      end

      def self.validate_that_all_copied_files_match
        Fastlane::Helper::ConfigureHelper.files_to_copy.each{ |x|

            source = absolute_secret_store_path(x["file"])
            destination = absolute_project_path(x["destination"])

            sourceHash = file_hash(source)
            destinationHash = file_hash(destination)

            unless sourceHash == destinationHash
                UI.user_error!("`#{x["destination"]} doesn't match the file in the secrets repository (#{x["file"]}) – unable to continue")
            end
        }
      end

      def self.absolute_project_path(relative_path)
        Fastlane::Helper::FilesystemHelper.absolute_project_path(relative_path)
      end

      def self.absolute_secret_store_path(relative_path)
        Fastlane::Helper::FilesystemHelper.absolute_secret_store_path(relative_path)
      end

      def self.file_hash(absolute_path)
        Fastlane::Helper::FilesystemHelper.file_hash(absolute_path)
      end

      def self.description
        "Ensure that the configuration is valid"
      end

      def self.authors
        ["Jeremy Massel"]
      end

      def self.details
        "Ensure that the configuration is valid"
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
