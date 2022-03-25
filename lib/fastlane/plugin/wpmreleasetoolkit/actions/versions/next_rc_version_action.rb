module Fastlane
  module Actions
    class NextRcVersionAction < Action
      def self.run(params)
        require 'octokit'
        require 'git'
        require_relative '../../helper/version_helper'

        client = Octokit::Client.new(access_token: params[:access_token])
        client.auto_paginate = true

        helper = Fastlane::Helper::VersionHelper.new(git: Git.open(params[:project_root]))

        version = Fastlane::Helper::Version.create(params[:version])
        next_version = helper.next_rc_for_version(version, repository: params[:project], github_client: client)

        UI.message "Next RC Version is #{next_version.rc}"

        next_version
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Return the next RC Version for this branch'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :access_token,
            env_name: 'GITHUB_TOKEN',
            description: 'The GitHub token to use when querying GitHub',
            type: String,
            sensitive: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :version,
            description: 'The current version',
            type: String,
            verify_block: proc { |v| UI.user_error!("Invalid version number: #{v}") if Fastlane::Helper::Version.create(v).nil? }
          ),
          FastlaneCore::ConfigItem.new(
            key: :project,
            description: 'The project slug (ex: `wordpress-mobile/wordpress-ios`)',
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :project_root,
            env_name: 'PROJECT_ROOT_FOLDER',
            description: 'The project root folder (that contains the .git directory)',
            type: String,
            default_value: Dir.pwd,
            verify_block: proc { |v| UI.user_error!("Directory does not exist: #{v}") unless File.directory? v }
          ),
        ]
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
