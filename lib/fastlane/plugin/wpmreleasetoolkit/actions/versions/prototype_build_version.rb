module Fastlane
  module Actions
    class PrototypeBuildVersionAction < Action
      def self.run(params)
        require 'git'
        require_relative '../../helper/version_helper'

        helper = Fastlane::Helper::VersionHelper.new(git: Git.open(params[:project_root]))

        {
          build_name: helper.prototype_build_name,
          build_number: helper.prototype_build_number
        }
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Return a prototype build version based on CI environment variables, and the current state of the repo'
      end

      def self.available_options
        [
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
