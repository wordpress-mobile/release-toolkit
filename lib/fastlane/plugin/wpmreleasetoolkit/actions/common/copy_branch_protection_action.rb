require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class CopyBranchProtectionAction < Action
      def self.run(params)
        repository = params[:repository]
        from_branch = params[:from_branch]
        to_branch = params[:to_branch]

        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])

        response = begin
          github_helper.get_branch_protection(
            repository:,
            branch: from_branch
          )
        rescue Octokit::NotFound
          UI.user_error!("Branch `#{from_branch}` of repository `#{repository}` was not found.")
        end
        UI.user_error!("Branch `#{from_branch}` does not have any branch protection set up.") if response.nil?
        settings = Fastlane::Helper::GithubHelper.branch_protection_api_response_to_normalized_hash(response)

        response = begin
          github_helper.set_branch_protection(
            repository:,
            branch: to_branch,
            **settings
          )
        rescue Octokit::NotFound
          UI.user_error!("Branch `#{to_branch}` of repository `#{repository}` was not found.")
        end

        Fastlane::Helper::GithubHelper.branch_protection_api_response_to_normalized_hash(response)
      end

      def self.description
        'Copies the branch protection settings of one branch onto another branch'
      end

      def self.details
        description
      end

      def self.return_value
        'The hash corresponding to the response returned by the API request, and containing the applied protection settings'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       env_name: 'GHHELPER_REPOSITORY',
                                       description: 'The remote path of the GH repository on which we work',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :from_branch,
                                       env_name: 'GHHELPER_FROM_BRANCH',
                                       description: 'The branch to copy the protection settings from',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :to_branch,
                                       env_name: 'GHHELPER_TO_BRANCH',
                                       description: 'The branch to copy the protection settings to',
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
  end
end
