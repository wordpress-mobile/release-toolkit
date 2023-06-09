require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class SetbranchprotectionAction < Action
      def self.run(params)
        repository = params[:repository]
        branch_name = params[:branch]

        branch_url = "https://api.github.com/repos/#{repository}/branches/#{branch_name}"
        restrictions = { url: "#{branch_url}/protection/restrictions", users_url: "#{branch_url}/protection/restrictions/users", teams_url: "#{branch_url}/protection/restrictions/teams", users: [], teams: [] }
        required_pull_request_reviews = { url: "#{branch_url}/protection/required_pull_request_reviews", dismiss_stale_reviews: false, require_code_owner_reviews: false }

        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])
        github_helper.set_branch_protection(
          repository: repository,
          branch: branch_name,
          restrictions: restrictions,
          enforce_admins: nil,
          required_pull_request_reviews: required_pull_request_reviews
        )
      end

      def self.description
        "Sets the 'release branch' protection state for the specified branch"
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Sets the 'release branch' protection state for the specified branch"
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
                                       description: 'The branch to protect',
                                       optional: false,
                                       type: String),
          Fastlane::Helper::GithubHelper.github_token_config_item,
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
