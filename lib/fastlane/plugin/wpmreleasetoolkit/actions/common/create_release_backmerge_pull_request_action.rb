require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class CreateReleaseBackmergePullRequestAction < Action
      DEFAULT_BRANCH = 'trunk'.freeze

      GIT_GRAPH_TYPES = %i[mermaid ascii both none].freeze
      GIT_GRAPH_TYPES_STRING = GIT_GRAPH_TYPES.map { |t| ":#{t}" }.join(', ').freeze

      def self.run(params)
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
            token: token,
            repository: repository,
            title: "Merge #{source_branch} into #{target_branch}",
            head_branch: source_branch,
            base_branch: target_branch,
            labels: labels,
            milestone: target_milestone&.number,
            reviewers: reviewers,
            team_reviewers: team_reviewers,
            intermediate_branch_created_callback: intermediate_branch_created_callback,
            git_graph_type: params[:git_graph_type]
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
      def self.create_backmerge_pr(token:, repository:, title:, head_branch:, base_branch:, labels:, milestone:, reviewers:, team_reviewers:, intermediate_branch_created_callback:, git_graph_type:)
        intermediate_branch = "merge/#{head_branch.gsub('/', '-')}-into-#{base_branch.gsub('/', '-')}"

        if Fastlane::Helper::GitHelper.branch_exists_on_remote?(branch_name: intermediate_branch)
          UI.user_error!("The intermediate branch `#{intermediate_branch}` already exists. Please check if there is an existing Pull Request that needs to be merged or closed first, or delete the branch.")
          return nil
        end

        Fastlane::Helper::GitHelper.create_branch(intermediate_branch)

        intermediate_branch_created_callback&.call(base_branch, intermediate_branch)

        # if there's a callback, make sure it didn't switch branches
        other_action.ensure_git_branch(branch: "^#{intermediate_branch}/") unless intermediate_branch_created_callback.nil?

        if Fastlane::Helper::GitHelper.point_to_same_commit?(base_branch, head_branch)
          UI.error("No differences between #{head_branch} and #{base_branch}. Skipping PR creation.")
          return nil
        end

        other_action.push_to_git_remote(tags: false)

        # Live playground to edit this graph
        # https://mermaid.live/edit#pako:eNqNkU1PwzAMhv9KZanqpWVFwCVHQOKCxoFrLl7itdGaZEoTTWjqf8eLOo2i8eGTPx77TewjKK8JBJTlUbqCzTgTRTEHJ6s6E18C7vtqkc4li8Y9BnSqX6MlBqoYkttV9Y_cW9AUGLxt2_Y7Nfb-8OStNfEVNzQwtcVhpCU1XUJ2p7KU7vzAXNlkmSLQQDjS6v7m4S7nVU9q51O8UsmSv7jzSEuho9Xc3pzaG-Oib_KXlxr_QL8onbuuVy9unvrXbKiBCV645qvme0mIPVmSINjVtMU0RAm8O0YxRf_-4RQIbqca0l5jpGeDXUALIu9_-gRejKzU
        meramid_git_graph = <<~GRAPH
          ```mermaid
          %%{
            init: {
              'gitGraph': {
                'mainBranchName': 'trunk',
                'mainBranchOrder': 1000,
                'showCommitLabel': false
              }
            }
          }%%
          gitGraph
             branch #{head_branch}
             checkout #{head_branch}
             commit
             commit
             commit
             branch #{intermediate_branch}
             checkout #{intermediate_branch}
             commit
             checkout #{base_branch}
             commit
             commit
             merge #{base_branch}
          ```
        GRAPH

        ascii_git_graph = <<~GRAPH
          ```
          #{head_branch.rjust(40)}  ----o-- - - -
          #{' ' * 40}       \\
          #{intermediate_branch.rjust(40)}        `---.
          #{' ' * 40}             \\
          #{base_branch.rjust(40)}  ------------x- - -
          ```
        GRAPH

        git_graph = case git_graph_type
                    when :both
                      <<~GRAPH
                        #{meramid_git_graph}

                        <details>
                        <summary>Expand to see an ASCII representation of the Git graph above</summary>

                        #{ascii_git_graph}
                      GRAPH
                    when :mermaid
                      meramid_git_graph
                    when :ascii
                      ascii_git_graph
                    when :none
                      ''
                    else
                      UI.user_error!("Unsupported Git graph type '#{params[:git_graph_type]}'")
                    end

        pr_body = <<~BODY
          Merging `#{head_branch}` into `#{base_branch}`.

          Via intermediate branch `#{intermediate_branch}`, to help fix conflicts if any:

          #{git_graph}
        BODY

        other_action.create_pull_request(
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
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       env_name: 'GHHELPER_REPOSITORY',
                                       description: 'The remote path of the GH repository on which we work',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :source_branch,
                                       description: 'The source branch to create a backmerge PR from, in the format `release/x.y.z`',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :default_branch,
                                       description: 'The default branch to target if no newer release branches exist',
                                       optional: true,
                                       default_value: DEFAULT_BRANCH,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :target_branches,
                                       description: 'Array of target branches for the backmerge. If empty, the action will determine target branches by finding all `release/x.y.z` branches with a `x.y.z` version greater than the version in source branch\'s name. If none are found, it will target `default_branch`', # rubocop:disable Layout/LineLength
                                       optional: true,
                                       default_value: [],
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :labels,
                                       description: 'The labels that should be assigned to the backmerge PRs',
                                       optional: true,
                                       default_value: [],
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :milestone_title,
                                       description: 'The title of the milestone to assign to the created PRs',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :reviewers,
                                       description: 'An array of GitHub users that will be assigned to the pull request',
                                       optional: true,
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :team_reviewers,
                                       description: 'An array of GitHub team slugs that will be assigned to the pull request',
                                       optional: true,
                                       type: Array),
          FastlaneCore::ConfigItem.new(key: :intermediate_branch_created_callback,
                                       description: 'Callback to allow for the caller to perform operations on the intermediate branch before pushing. The call back receives two parameters: the base (target) branch for the PR and the intermediate branch name',
                                       optional: true,
                                       type: Proc),
          FastlaneCore::ConfigItem.new(key: :git_graph_type,
                                       description: "The type of Git graph to show. Possible values: #{GIT_GRAPH_TYPES_STRING}",
                                       optional: true,
                                       type: Symbol,
                                       default_value: :both,
                                       verify_block: proc do |value|
                                         UI.user_error!("Unsupported Git graph type '#{value}'. Supported values are: #{GIT_GRAPH_TYPES_STRING}.") unless GIT_GRAPH_TYPES.include?(value)
                                       end),
          Fastlane::Helper::GithubHelper.github_token_config_item,
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
