require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class RemoveBranchProtectionAction < Action
      def self.run(params)
        repository = params[:repository]
        branch_name = params[:branch]

        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])
        github_helper.remove_branch_protection(
          repository:,
          branch: branch_name
        )
      rescue Octokit::NotFound
        UI.user_error!("Branch `#{branch_name}` of repository `#{repository}` was not found.")
      rescue Octokit::BranchNotProtected
        UI.message("Note: Branch `#{branch_name}` was not protected in the first place.")
      end

      def self.description
        'Removes the protection settings for the specified branch'
      end

      def self.details
        description
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       env_name: 'GHHELPER_REPOSITORY',
                                       description: 'The remote path of the GH repository on which we work',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :branch,
                                       env_name: 'GHHELPER_BRANCH',
                                       description: 'The branch to unprotect',
                                       optional: false,
                                       type: String),
          Fastlane::Helper::GithubHelper.github_token_config_item,
        ]
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        true
      end
    end

    # For backwards compatibility
    class RemovebranchprotectionAction < RemoveBranchProtectionAction
      def self.category
        :deprecated
      end

      def self.deprecated_notes
        "This action has been renamed `#{superclass.action_name}`"
      end
    end
  end
end
