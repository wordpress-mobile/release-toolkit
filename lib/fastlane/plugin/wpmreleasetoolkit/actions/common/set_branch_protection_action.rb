require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class SetBranchProtectionAction < Action
      def self.run(params)
        repository = params[:repository]
        branch_name = params[:branch]
        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])

        settings = if params[:keep_existing_settings_unchanged]
                     Fastlane::Helper::GithubHelper.branch_protection_api_response_to_normalized_hash(
                       github_helper.get_branch_protection(repository: repository, branch: branch_name)
                     )
                   else
                     {}
                   end

        # `required_status_checks` field — only override existing `checks` subfield if param provided
        unless params[:required_ci_checks].nil?
          if params[:required_ci_checks].empty?
            settings[:required_status_checks] = nil # explicitly completely delete existing check requirement
          else
            settings[:required_status_checks] ||= { strict: false }
            settings[:required_status_checks][:checks] = params[:required_ci_checks].map { |ctx| { context: ctx } }
          end
        end

        # `enforce_admins` field — only override existing value if param provided
        if params[:enforce_admins].nil?
          settings[:enforce_admins] ||= nil # parameter is required to be provided, even if nil (aka false) value
        else
          settings[:enforce_admins] = params[:enforce_admins]
        end

        # `required_pull_request_reviews` field — only override `required_approving_review_count` subfield if param provided
        settings[:required_pull_request_reviews] ||= {
          dismiss_stale_reviews: false,
          require_code_owner_reviews: false
        }
        unless params[:required_approving_review_count].nil?
          settings[:required_pull_request_reviews][:required_approving_review_count] = params[:required_approving_review_count]
        end

        # `restrictions` field
        settings[:restrictions] ||= { users: [], teams: [] }

        # `allow_force_pushes` field — only override existing value if param provided
        unless params[:allow_force_pushes].nil?
          settings[:allow_force_pushes] = params[:allow_force_pushes]
        end

        # `lock_branch` field — only override existing value if param provided
        unless params[:lock_branch].nil?
          settings[:lock_branch] = params[:lock_branch]
        end

        # API Call - See https://docs.github.com/en/rest/branches/branch-protection#update-branch-protection
        response = github_helper.set_branch_protection(
          repository: repository,
          branch: branch_name,
          **settings
        )

        Fastlane::Helper::GithubHelper.branch_protection_api_response_to_normalized_hash(response)
      rescue Octokit::NotFound => e
        UI.user_error!("Branch `#{branch_name}` of repository `#{repository}` was not found.\n#{e.message}")
      end

      def self.description
        'Sets the protection state for the specified branch'
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
                                       description: 'The slug of the GH repository on which we work',
                                       optional: false,
                                       type: String),
          # NOTE: GitHub branch protection API doesn't allow wildcard characters for the branch parameter
          FastlaneCore::ConfigItem.new(key: :branch,
                                       env_name: 'GHHELPER_BRANCH',
                                       description: 'The branch to protect',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :keep_existing_settings_unchanged,
                                       description: 'If set to true, will only change the settings that are explicitly provided to the action, ' \
                                       + 'while keeping the values of other existing protection settings (if any) unchanged. If false, it will ' \
                                       + 'discard any existing branch protection setting if any before setting just the ones provided ' \
                                       + '(and leaving the rest with default GitHub values)',
                                       default_value: true,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :required_ci_checks,
                                       description: 'If provided, specifies the list of CI status checks to mark as required. If not provided (nil), will keep existing ones',
                                       optional: true,
                                       default_value: nil,
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :required_approving_review_count,
                                       description: 'If not nil, change the number of approving reviews required to merge the PR. ' \
                                       + 'Acceptable values are `nil` (do not change), 0 (disable) or a number between 1–6',
                                       optional: true,
                                       default_value: nil,
                                       type: Integer),
          FastlaneCore::ConfigItem.new(key: :enforce_admins,
                                       description: 'If provided, will update the setting of whether admins can bypass restrictions (false) or not (true)',
                                       optional: true,
                                       default_value: nil,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :allow_force_pushes,
                                       description: 'If provided, will update the setting of whether to allow force pushes on the branch',
                                       optional: true,
                                       default_value: nil,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :lock_branch,
                                       description: 'If provided, will update the locked (aka readonly) state of the branch',
                                       optional: true,
                                       default_value: nil,
                                       type: Boolean),
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
    class SetbranchprotectionAction < SetBranchProtectionAction
      def self.category
        :deprecated
      end

      def self.deprecated_notes
        "This action has been renamed `#{superclass.action_name}`"
      end
    end
  end
end
