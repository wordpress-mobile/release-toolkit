require 'fastlane/action'
require 'rubygems/command_manager'
require 'securerandom'

module Fastlane
  module Actions
    class CommentOnPrAction < Action
      def self.run(params)
        require_relative '../../helper/github_helper'

        Fastlane::Helper::GithubHelper.comment_on_pr(
          project_slug: params[:project],
          pr_number: params[:pr_number],
          body: params[:body],
          reuse_identifier: params[:reuse_identifier]
        )
      end

      def self.description
        'Post a comment on a given PR number (optionally updating an existing one)'
      end

      def self.authors
        ['Jeremy Massel']
      end

      def self.details
        <<~DETAILS
          If used just once, this method makes it nice and easy to post a quick comment to a GitHub
          PR. Subsequent runs will allow you to update an existing comment as many times as you need
          to (for instance, across multiple CI runs).

          The `:reuse_identifier` config item enables this.
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :access_token,
            env_name: 'GITHUB_TOKEN',
            description: 'The GitHub token to use for posting the comment',
            is_string: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :reuse_identifier,
            description: 'If provided, the reuse identifier can identify an existing comment to overwrite',
            is_string: true,
            default_value: SecureRandom.uuid
          ),
          FastlaneCore::ConfigItem.new(
            key: :project,
            description: 'The project slug (ex: `rails/rails`)',
            is_string: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :pr_number,
            description: 'The PR number',
            is_string: false # integer
          ),
          FastlaneCore::ConfigItem.new(
            key: :body,
            description: 'The content of the comment',
            is_string: true
          ),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
