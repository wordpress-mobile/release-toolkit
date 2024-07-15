require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class CreateReleaseBackmergePullRequestAction < Action
      DEFAULT_BRANCH = 'trunk'.freeze

      def self.run(params)
        token = params[:github_token]
        repository = params[:repository]
        release_branch = params[:release_branch]
        default_branch = params[:default_branch]
        target_branches_param = params[:target_branches]
        labels = params[:labels]
        milestone_title = params[:milestone_title]

        unless release_branch.start_with?('release/')
          UI.user_error!('`release_branch` must start with `release/`')
        end

        if target_branches_param.include?(release_branch)
          UI.user_error!('`target_branches` must not contain `release_branch`')
        end

        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])
        target_milestone = milestone_title.nil? ? nil : github_helper.get_milestone(repository, milestone_title)

        target_branches = if target_branches_param.empty?
                            determine_target_branches(release_branch.delete('release/'), default_branch)
                          else
                            target_branches_param
                          end

        target_branches.map do |target_branch|
          Fastlane::Helper::GitHelper.checkout_and_pull(release_branch)

          create_backmerge_pr(
            token: token,
            repository: repository,
            title: "Merge #{release_branch} into #{target_branch}",
            head_branch: release_branch,
            base_branch: target_branch,
            milestone: target_milestone&.number,
            labels: labels
          )
        end
      end

      def self.determine_target_branches(release_version, default_branch)
        release_branches = Actions.sh('git', 'branch', '-r', '-l', 'origin/release/*').chomp

        all_release_branches_versions = release_branches
                                        .split("\n")
                                        .map { |branch| branch.match(%r{origin/release/([0-9.]*)})&.captures&.first }
                                        .compact

        target_branches = all_release_branches_versions.select { |branch| Gem::Version.new(branch) > Gem::Version.new(release_version) }
                                                       .map { |v| "release/#{v}" }
        target_branches = [default_branch] if target_branches.empty?

        target_branches
      end

      def self.create_backmerge_pr(token:, repository:, title:, head_branch:, base_branch:, milestone:, labels:)
        intermediate_branch = "merge/#{head_branch.gsub('/', '-')}-into-#{base_branch.gsub('/', '-')}"
        Fastlane::Helper::GitHelper.create_branch(intermediate_branch)

        other_action.push_to_git_remote(tags: false)

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
          api_token: token,
          repo: repository,
          title: title,
          body: pr_body,
          head: intermediate_branch,
          base: base_branch,
          labels: labels,
          milestone: milestone
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
        'The list of backmerge PRs created'
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
          FastlaneCore::ConfigItem.new(key: :release_branch,
                                       description: 'The release branch, in the format `release/x.y.z`',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :default_branch,
                                       description: 'The default branch to target if no newer release branches exist',
                                       optional: true,
                                       default_value: DEFAULT_BRANCH,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :target_branches,
                                       description: 'Array of target branches for the backmerge. If empty, the action will determine target branches by finding all `release/x.y.z` branches with a version greater than `release_version`. If none are found, it will target `default_branch`',
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
          Fastlane::Helper::GithubHelper.github_token_config_item,
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
