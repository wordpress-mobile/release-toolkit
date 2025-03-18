# frozen_string_literal: true

require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class CreateReleaseBackmergePullRequestAction < Action
      DEFAULT_BRANCH = 'trunk'

      def self.run(params)
        api_url = params[:api_url]
        token = params[:github_token]
        repository = params[:repository]
        source_branch = params[:source_branch]
        default_branch = params[:default_branch]
        target_branches = params[:target_branches]
        labels = params[:labels]
        milestone_title = params[:milestone_title]
        reviewers = params[:reviewers]
        team_reviewers = params[:team_reviewers]
        intermediate_branch_created_callback = params[:intermediate_branch_created_callback]

        if target_branches.include?(source_branch)
          UI.user_error!('`target_branches` must not contain `source_branch`')
        end

        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])
        target_milestone = milestone_title.nil? ? nil : github_helper.get_milestone(repository, milestone_title)

        final_target_branches = if target_branches.empty?
                                  unless source_branch.start_with?('release/')
                                    UI.user_error!('`source_branch` must start with `release/`')
                                  end

                                  determine_target_branches(source_release_version: source_branch.delete('release/'), default_branch: default_branch)
                                else
                                  target_branches
                                end

        final_target_branches.map do |target_branch|
          Fastlane::Helper::GitHelper.checkout_and_pull(source_branch)

          create_backmerge_pr(
            api_url: api_url,
            token: token,
            repository: repository,
            title: "Merge #{source_branch} into #{target_branch}",
            head_branch: source_branch,
            base_branch: target_branch,
            labels: labels,
            milestone: target_milestone&.number,
            reviewers: reviewers,
            team_reviewers: team_reviewers,
            intermediate_branch_created_callback: intermediate_branch_created_callback
          )
        end.compact
      end

      # Determines the target branches for a release version.
      #
      # @param source_release_version [String] the source release version to compare against other release branches.
      # @param default_branch [String] the default branch to use if no target branches are found.
      # @return [Array<String>] the list of target branches greater than the release version.
      def self.determine_target_branches(source_release_version:, default_branch:)
        release_branches = Actions.sh('git', 'branch', '-r', '-l', 'origin/release/*').strip.split("\n")

        all_release_branches_versions = release_branches
                                        .map { |branch| branch.match(%r{origin/release/([0-9.]*)})&.captures&.first }
                                        .compact

        target_branches = all_release_branches_versions.select { |branch| Gem::Version.new(branch) > Gem::Version.new(source_release_version) }
                                                       .map { |v| "release/#{v}" }
        target_branches = [default_branch] if target_branches.empty?

        target_branches
      end

      # Creates a backmerge pull request using the `create_pull_request` Fastlane Action.
      #
      # @param api_url [String] the GitHub API URL to use for creating the pull request
      # @param token [String] the GitHub token for authentication.
      # @param repository [String] the repository where the pull request will be created.
      # @param title [String] the title of the pull request.
      # @param head_branch [String] the source branch for the pull request.
      # @param base_branch [String] the target branch for the pull request.
      # @param labels [Array<String>] the labels to add to the pull request.
      # @param milestone [String] the milestone to associate with the pull request.
      # @param reviewers [Array<String>] the individual reviewers for the pull request.
      # @param team_reviewers [Array<String>] the team reviewers for the pull request.
      # @param intermediate_branch_created_callback [Proc] A callback to call after having created the intermediate branch
      #        to allow the caller to e.g. add new commits on it before the PR is created. The callback takes two parameters: the base branch and the intermediate branch
      #
      # @return [String] The URL of the created Pull Request, or `nil` if no PR was created.
      #
      def self.create_backmerge_pr(api_url:, token:, repository:, title:, head_branch:, base_branch:, labels:, milestone:, reviewers:, team_reviewers:, intermediate_branch_created_callback:) # rubocop:disable Metrics/ParameterLists
        # Do an early pre-check to see if the PR would be valid, but only if no callback (as a callback might add new commits on intermediate branch)
        if intermediate_branch_created_callback.nil? && !can_merge?(head_branch, into: base_branch)
          UI.error("Nothing to merge from #{head_branch} into #{base_branch}. Skipping PR creation.")
          return nil
        end

        # Create the intermediate branch
        intermediate_branch = "merge/#{head_branch.gsub('/', '-')}-into-#{base_branch.gsub('/', '-')}"
        if Fastlane::Helper::GitHelper.branch_exists_on_remote?(branch_name: intermediate_branch)
          UI.important("An intermediate branch `#{intermediate_branch}` already exists on the remote. It will be deleted and GitHub will close any associated existing PR.")
          Fastlane::Helper::GitHelper.delete_remote_branch_if_exists!(intermediate_branch)
        end
        Fastlane::Helper::GitHelper.delete_local_branch_if_exists!(intermediate_branch)
        Fastlane::Helper::GitHelper.create_branch(intermediate_branch)

        # Call the callback if one was provided to allow the use to add commits on the intermediate branch (e.g. solve conflicts)
        unless intermediate_branch_created_callback.nil?
          intermediate_branch_created_callback.call(base_branch, intermediate_branch)
          # Make sure the callback block didn't switch branches
          other_action.ensure_git_branch(branch: "^#{intermediate_branch}$")

          # When a callback was provided, do the pre-check about valid PR _only_ at that point, in case the callback added new commits
          unless can_merge?(intermediate_branch, into: base_branch)
            UI.error("Nothing to merge from #{intermediate_branch} into #{base_branch}. Skipping PR creation.")
            Fastlane::Helper::GitHelper.delete_local_branch_if_exists!(intermediate_branch)
            return nil
          end
        end

        other_action.push_to_git_remote(tags: false, remote_branch: intermediate_branch, set_upstream: true)

        pr_body = <<~BODY
          Merging `#{head_branch}` into `#{base_branch}`.

          Via intermediate branch `#{intermediate_branch}`, to help fix conflicts if any:
          ```
          #{head_branch.rjust(40)}  ----o-- - - -
          #{' ' * 40}       \\
          #{intermediate_branch.rjust(40)}        `---.
          #{' ' * 40}             \\
          #{base_branch.rjust(40)}  ------------x- - -
          ```
        BODY

        other_action.create_pull_request(
          api_url: api_url,
          api_token: token,
          repo: repository,
          title: title,
          body: pr_body,
          head: intermediate_branch,
          base: base_branch,
          labels: labels,
          milestone: milestone,
          reviewers: reviewers,
          team_reviewers: team_reviewers
        )
      end

      # Determine if a `head->base` PR would be considered valid by GitHub.
      #
      # Note that a PR with an empty diff can still be valid (e.g. if you merge a commit and its revert)
      #
      # This method returns false mostly when all commits from `head` has already been merged into `base`
      # and that there are no new commits to merge (in which case GitHub would refuse creating the PR)
      #
      # @param head [String] the head reference (commit sha or branch name) we want to merge
      # @param into [String] the base reference (commit sha or branch name) we want to merge into
      # @return [Boolean] true if there are commits in `head` that are not yet in `base` and a merge can happen;
      #                   false if all commits from `head` are already in `base` and a merge would be rejected
      #
      def self.can_merge?(head, into:)
        merge_base = Fastlane::Helper::GitHelper.find_merge_base(into, head)
        !Fastlane::Helper::GitHelper.point_to_same_commit?(merge_base, head)
      end

      def self.description
        'Creates backmerge PRs for a release branch into target branches'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_type
        :array_of_strings
      end

      def self.return_value
        'The list of the created backmerge Pull Request URLs'
      end

      def self.details
        <<~DETAILS
          This action creates backmerge Pull Requests from a release branch into one or more target branches.

          It can be used to ensure that changes from a release branch are merged back into other branches, such as newer release branches or the main development branch (e.g., `trunk`).
        DETAILS
      end

      def self.available_options
        # Parameters we want to forward from Fastlane's create_pull_request action
        forwarded_param_keys = %i[
          api_url
          labels
          assignees
          reviewers
          team_reviewers
        ].freeze

        forwarded_params = Fastlane::Actions::CreatePullRequestAction.available_options.select do |opt|
          forwarded_param_keys.include?(opt.key)
        end

        [
          *forwarded_params,
          Fastlane::Helper::GithubHelper.github_token_config_item, # we forward `github_token` to `api_token` in the `create_pull_request` action
          FastlaneCore::ConfigItem.new(
            key: :repository,
            env_name: 'GHHELPER_REPOSITORY',
            description: 'The remote path of the GH repository on which we work',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :source_branch,
            description: 'The source branch to create a backmerge PR from, in the format `release/x.y.z`',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :default_branch,
            description: 'The default branch to target if no newer release branches exist',
            optional: true,
            default_value: DEFAULT_BRANCH,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :target_branches,
            description: 'Array of target branches for the backmerge. If empty, the action will determine target branches by finding all `release/x.y.z` branches with a `x.y.z` version greater than the version in source branch\'s name. If none are found, it will target `default_branch`',
            optional: true,
            default_value: [],
            type: Array
          ),
          FastlaneCore::ConfigItem.new(
            key: :milestone_title,
            description: 'The title of the milestone to assign to the created PRs',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :intermediate_branch_created_callback,
            description: 'Callback to allow for the caller to perform operations on the intermediate branch (e.g. pushing new commits to pre-solve conflicts) before creating the PR. ' \
             + 'The callback receives two parameters: the base (target) branch for the PR and the intermediate branch name that has been created.' \
             + 'Note that if you use the callback to add new commits to the intermediate branch, you are responsible for git-pushing them too',
            optional: true,
            type: Proc
          ),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
