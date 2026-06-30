# frozen_string_literal: true

require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class UploadGithubReleaseAssetsAction < Action
      def self.run(params)
        repository = params[:repository]
        version = params[:version]
        assets = params[:release_assets]
        replace_existing = params[:replace_existing]

        UI.message("Uploading #{assets.count} GitHub Release asset(s) to #{repository} #{version}.")

        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])
        url = github_helper.upload_release_assets(
          repository: repository,
          version: version,
          assets: assets,
          replace_existing: replace_existing
        )

        UI.success("Successfully uploaded GitHub Release assets. You can see the release at '#{url}'")
        url
      end

      def self.description
        'Uploads assets to an existing GitHub Release'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'The URL of the GitHub Release'
      end

      def self.details
        'Uploads assets to an existing GitHub Release. By default, existing release assets with matching filenames are replaced; when replace_existing is false, matching assets cause the action to fail.'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       description: 'The slug (`<org>/<repo>`) of the GitHub repository containing the release',
                                       optional: false,
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!('Repository cannot be empty') if value.to_s.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :version,
                                       description: 'The version of the release. Used as the git tag name',
                                       optional: false,
                                       type: String,
                                       verify_block: proc do |value|
                                         UI.user_error!('Version cannot be empty') if value.to_s.empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :release_assets,
                                       description: 'Assets to upload',
                                       type: Array,
                                       optional: false,
                                       verify_block: proc do |value|
                                         UI.user_error!('You must provide at least one release asset') if value.nil? || value.empty?
                                         value.each do |asset|
                                           UI.user_error!('release_assets must contain file paths') unless asset.is_a?(String) && !asset.empty?
                                         end
                                       end),
          FastlaneCore::ConfigItem.new(key: :replace_existing,
                                       description: 'True to delete existing release assets with matching filenames before uploading. False to fail if a matching asset exists',
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
