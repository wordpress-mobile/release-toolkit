# frozen_string_literal: true

require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class FindOrCreatePullRequestAction < Action
      def self.run(params)
        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])

        existing_pr = github_helper.find_pull_request(
          repository: params[:repository],
          head: params[:head],
          base: params[:base]
        )

        unless existing_pr.nil?
          UI.message("An open Pull Request already exists for `#{params[:head]}`: #{existing_pr.html_url}")
          return existing_pr.html_url
        end

        other_action.create_pull_request(
          api_url: params[:api_url],
          api_token: params[:github_token],
          repo: params[:repository],
          title: params[:title],
          body: params[:body],
          head: params[:head],
          base: params[:base],
          labels: params[:labels],
          assignees: params[:assignees],
          reviewers: params[:reviewers],
          team_reviewers: params[:team_reviewers],
          milestone: params[:milestone]
        )
      end

      def self.description
        'Returns the URL of the open Pull Request for a head branch, creating one if none exists yet'
      end

      def self.details
        <<~DETAILS
          Looks for an open Pull Request whose head is the given branch and which targets the given base,
          and returns its URL if found. Otherwise, creates a new Pull Request and returns its URL.

          This is useful for "rolling" automations (e.g. a daily translations or dependency-update job) that
          force-push the same head branch on every run: GitHub automatically refreshes the diff of the existing
          PR, so this action only needs to open a PR the first time.
        DETAILS
      end

      def self.authors
        ['Automattic']
      end

      def self.return_type
        :string
      end

      def self.return_value
        'The URL of the existing or newly-created Pull Request'
      end

      def self.available_options
        # Parameters we forward as-is from Fastlane's `create_pull_request` action
        forwarded_param_keys = %i[
          api_url
          labels
          assignees
          reviewers
          team_reviewers
          milestone
        ].freeze

        forwarded_params = Fastlane::Actions::CreatePullRequestAction.available_options.select do |opt|
          forwarded_param_keys.include?(opt.key)
        end

        [
          *forwarded_params,
          Fastlane::Helper::GithubHelper.github_token_config_item, # forwarded to `api_token` in the `create_pull_request` action
          FastlaneCore::ConfigItem.new(
            key: :repository,
            env_name: 'GHHELPER_REPOSITORY',
            description: 'The remote path of the GH repository on which we work, e.g. `wordpress-mobile/wordpress-ios`',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :title,
            description: 'The title of the Pull Request to create if none exists yet',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :body,
            description: 'The body of the Pull Request to create if none exists yet',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :head,
            description: 'The head branch of the Pull Request (the branch with the changes)',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :base,
            description: 'The base branch the Pull Request targets (e.g. `trunk`)',
            optional: false,
            type: String
          ),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
