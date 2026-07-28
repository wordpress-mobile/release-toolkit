# frozen_string_literal: true

require 'fastlane/action'
require 'date'
require_relative '../../helper/github_helper'
module Fastlane
  module Actions
    class CreateGithubReleaseAction < Action
      def self.run(params)
        repository = params[:repository]
        version = params[:version]
        assets = params[:release_assets]
        release_notes = params[:release_notes_file_path].nil? ? '' : File.read(params[:release_notes_file_path])
        # Replace full URLs to PRs/Issues that are in `[https://some-url]` brackets with shorthand, because GitHub does not render them properly otherwise.
        # That syntax is sometimes used by devs in `RELEASE-NOTES.txt` when pointing to a PR to another repo (e.g. Gutenberg PR from WP repo).
        # We should NOT transform URLs to PRs/Issues that are in `[text](url)` form (those are valid), only the ones directly in `[]` brackets.
        release_notes = release_notes.gsub(%r{\[https://github.com/([^/]*/[^/]*)/(pulls?|issues?)/([0-9]*)\]}, '[\1#\3]')
        prerelease = params[:prerelease]
        is_draft = params[:is_draft]

        UI.message("Creating #{'draft ' if is_draft}release #{version} in #{repository}.")
        # Verify assets
        assets.each do |file_path|
          UI.user_error!("Can't find file #{file_path}!") unless File.exist?(file_path)
        end

        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])
        url = github_helper.create_release(
          repository: repository,
          version: version,
          name: params[:name],
          target: params[:target],
          description: release_notes,
          assets: assets,
          prerelease: prerelease,
          is_draft: is_draft
        )
        UI.success("Successfully created GitHub Release. You can see it at '#{url}'")
        url
      end

      def self.description
        'Creates a release and uploads the provided assets'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'The URL of the created GitHub Release'
      end

      def self.details
        # Optional:
        'Creates a release and uploads the provided assets'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       env_name: 'GHHELPER_REPOSITORY',
                                       description: 'The slug (`<org>/<repo>`) of the GitHub repository we want to create the release on',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: 'GHHELPER_CREATE_RELEASE_VERSION',
                                       description: 'The version of the release. Used as the git tag name',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :name,
                                       description: 'The display name (title) of the GitHub release. Defaults to the version if not provided',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :target,
                                       env_name: 'GHHELPER_TARGET_COMMITISH',
                                       description: 'The branch name or commit SHA the new tag should point to - if that tag does not exist yet when publishing the release. If omitted, will default to the current HEAD commit at the time of this call',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :release_notes_file_path,
                                       env_name: 'GHHELPER_CREATE_RELEASE_NOTES',
                                       description: 'The path to the file that contains the release notes',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :release_assets,
                                       env_name: 'GHHELPER_CREATE_RELEASE_ASSETS',
                                       description: 'Assets to upload',
                                       type: Array,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :prerelease,
                                       env_name: 'GHHELPER_CREATE_RELEASE_PRERELEASE',
                                       description: 'True if this is a pre-release',
                                       optional: true,
                                       default_value: false,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :is_draft,
                                       env_name: 'GHHELPER_CREATE_RELEASE_IS_DRAFT',
                                       description: 'True to create the GitHub release as a draft (instead of publishing it immediately)',
                                       optional: true,
                                       default_value: true,
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
