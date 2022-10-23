require 'fastlane/action'

module Fastlane
  module Actions
    module SharedValues
      PR_COMMENT_REUSE_IDENTIFIER = :PR_COMMENT_REUSE_IDENTIFIER
    end

    class CommentOnPrAction < Action
      def self.run(params)
        require_relative '../../helper/github_helper'

        access_token = params[:access_token]
        github_helper = Fastlane::Helper::GithubHelper.new(github_token: access_token)

        reuse_identifier = github_helper.comment_on_pr(
          project_slug: params[:project],
          pr_number: params[:pr_number],
          body: params[:body],
          reuse_identifier: params[:reuse_identifier]
        )

        Actions.lane_context[SharedValues::PR_COMMENT_REUSE_IDENTIFIER] = reuse_identifier

        reuse_identifier
      end

      def self.description
        'Post a comment on a given PR number (optionally updating an existing one)'
      end

      def self.authors
        ['Automattic']
      end

      def self.details
        <<~DETAILS
          If used just once, this method makes it nice and easy to post a quick comment to a GitHub PR.

          Subsequent runs will allow you to update an existing comment as many times as you need to
          (e.g. across multiple CI runs), by using a `:reuse_identifier` to identify the comment to update.
        DETAILS
      end

      def self.available_options
        [
          Fastlane::Helper::GithubHelper.github_token_config_item,
          FastlaneCore::ConfigItem.new(
            key: :reuse_identifier,
            description: 'If provided, the reuse identifier can identify an existing comment to overwrite',
            type: String,
            default_value: nil
          ),
          FastlaneCore::ConfigItem.new(
            key: :project,
            description: 'The project slug (ex: `wordpress-mobile/wordpress-ios`)',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :pr_number,
            description: 'The PR number',
            type: Integer
          ),
          FastlaneCore::ConfigItem.new(
            key: :body,
            description: 'The content of the comment',
            type: String
          ),
        ]
      end

      def self.output
        [
          ['PR_COMMENT_REUSE_IDENTIFIER', 'The `reuse_identifier` for the most recently posted comment'],
        ]
      end

      def self.return_value
        'The `reuse_identifier` for the posted comment (useful for updating it later, if needed)'
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
