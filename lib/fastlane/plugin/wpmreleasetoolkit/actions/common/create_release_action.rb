require 'fastlane/action'
require 'date'
require_relative '../../helper/github_helper'
require_relative '../../helper/ios/ios_version_helper'
require_relative '../../helper/android/android_version_helper'
module Fastlane
  module Actions
    class CreateReleaseAction < Action
      def self.run(params)
        repository = params[:repository]
        version = params[:version]
        assets = params[:release_assets]
        release_notes = params[:release_notes_file_path].nil? ? '' : File.read(params[:release_notes_file_path])
        # Replace full URLS to PRs/Issues with shorthand, because GitHub does not render them properly otherwise.
        release_notes.gsub!(%r{https://github.com/([^/]*/[^/]*)/(pulls?|issues?)/([0-9]*)}, '\1#\3')
        prerelease = params[:prerelease]
        token = params[:github_token]

        UI.message("Creating draft release #{version} in #{repository}.")
        # Verify assets
        assets.each do |file_path|
          UI.user_error!("Can't find file #{file_path}!") unless File.exist?(file_path)
        end

        github_helper = Fastlane::Helper::GithubHelper.new(github_token: token)

        github_helper.create_release(
          repository: repository,
          version: version,
          target: params[:target],
          description: release_notes,
          assets: assets,
          prerelease: prerelease
        )
        UI.message('Done')
      end

      def self.description
        'Creates a release and uploads the provided assets'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
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
                                       description: 'The version of the release',
                                       optional: false,
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
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :github_token,
                                       env_name: 'GITHUB_TOKEN',
                                       description: 'The GitHub OAuth access token',
                                       optional: false,
                                       default_value: false,
                                       type: String),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
