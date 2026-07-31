# frozen_string_literal: true

require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class PublishGithubReleaseAction < Action
      def self.run(params)
        repository = params[:repository]
        name = params[:name]
        prerelease = params[:prerelease]

        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])

        url = github_helper.publish_release(
          repository: repository,
          name: name,
          prerelease: prerelease == :unchanged ? nil : prerelease
        )
        UI.success("Successfully published GitHub Release #{name}. You can see it at '#{url}'")
        url
      end

      def self.description
        'Publish an existing GitHub Release still in draft mode'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'The URL of the published GitHub Release'
      end

      def self.details
        <<~DETAILS
          Publish an existing draft GitHub Release.

          If several GitHub Releases share the same `name`, the most recently created one is published,
          as it is the one targeting the latest commit of the release branch.
          #{' '}
          (Multiple releases can exist with the same `name` when the release finalization automation
          is run more than once for the same version, each run creating its own draft.)
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       description: 'The slug (`<org>/<repo>`) of the GitHub repository we want to create the release on',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :name,
                                       description: 'The name (aka title) of the draft release to publish',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :prerelease,
                                       description: 'True to publish as a pre-release. False to published as final. Don\'t provide a value to keep the same (non-)prerelease status as the one used in the Draft',
                                       optional: true,
                                       default_value: :unchanged,
                                       type: Boolean),
          Fastlane::Helper::GithubHelper.github_token_config_item,
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
