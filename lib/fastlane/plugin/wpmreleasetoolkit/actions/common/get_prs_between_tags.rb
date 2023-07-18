require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class GetPrsBetweenTagsAction < Action
      def self.run(params)
        repository = params[:repository]
        tag_name = params[:tag_name]
        target_commitish = params[:target_commitish]
        previous_tag = params[:previous_tag]
        config_file_path = params[:configuration_file_path]
        gh_token = params[:github_token]

        # Get commit list
        github_helper = Fastlane::Helper::GithubHelper.new(github_token: gh_token)
        changelog = begin
          github_helper.generate_release_notes(
            repository: repository,
            tag_name: tag_name,
            previous_tag: previous_tag,
            target_commitish: target_commitish,
            config_file_path: config_file_path
          )
        rescue StandardError => e
          error_msg = "❌ Error computing the list of PRs since #{previous_tag}: `#{e.message}`"
          UI.important(error_msg)
          error_msg # Use error message as GitHub Release body to help us be aware of what went wrong.
        end

        previous_release_link = github_helper.get_release_url(repository: repository, tag_name: previous_tag)
        changelog
          .gsub("## What's Changed", "## New PRs since [#{previous_tag}](#{previous_release_link})\n")
      end

      def self.description
        'Gets a markdown text containing the list of PRs that have been merged between two git tags'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'The markdown-formatted string listing the PRs between the provided tags'
      end

      def self.details
        <<~DETAILS
          Uses the GitHub API to get a generated changelog consisting of the list of PRs that have been merged between two git tags.
          The list of PRs can optionally be categorized using a config file (typically living at `.github/release.yml`)

          This is typically useful to generate a CHANGELOG-style list of PRs for a given build since a last build. For example:

          - List PRs between current beta that we just built (e.g. 12.3-rc-4) and the previous beta of the same version:
              git_prs_between_tags(tag_name: '12.3-rc-4', previous_tag: '12.3-rc-3')
          - List all PRs that landed since the last stable/final release:
              git_prs_between_tags(tag_name: '12.3-rc-4', previous_tag: '12.2')

          Tip: You can use the `find_previous_tag` action to help you find the previous_tag matching an expected pattern (like `12.3-rc-*`)

          See https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#generate-release-notes-content-for-a-release
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       env_name: 'GIT_REPO_SLUG',
                                       description: 'The repository name, including the organization (e.g. `wordpress-mobile/wordpress-ios`). ' \
                                                    'Extracted from the `BUILDKITE_REPO` or the git remote URL if not provided explicitly',
                                       default_value_dynamic: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :tag_name,
                                       description: 'The name of the tag for the release we are about to create. This can be an existing tag or a new one',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :target_commitish,
                                       description: 'Specifies the commitish value that will be the target for the release\'s tag. ' \
                                                    'Required if the supplied `tag_name` does not reference an existing tag. Ignored if the tag_name already exists. ' \
                                                    'Defaults to the commit sha of the current HEAD',
                                       optional: true,
                                       default_value: `git rev-parse HEAD`.chomp,
                                       default_value_dynamic: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :previous_tag,
                                       description: 'The name of the previous tag to use as the starting point for the release notes. ' \
                                                    'If not provided explicitly, GitHub will use the last tag as the starting point',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :configuration_file_path,
                                       description: 'Path to a file in the repository containing configuration settings used for generating the release notes. ' \
                                                    'If unspecified, the configuration file located in the repository at `.github/release.yml` or `.github/release.yaml` will be used. ' \
                                                    'If that is not present, the default configuration will be used. ' \
                                                    'See https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes#configuration-options',
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
