require 'fastlane/action'
require 'date'
require_relative '../../helper/github_helper'
require_relative '../../helper/ios/ios_version_helper'
require_relative '../../helper/android/android_version_helper'
module Fastlane
  module Actions
    class CloseMilestoneAction < Action
      def self.run(params)
        repository = params[:repository]
        milestone_title = params[:milestone]

        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])
        milestone = github_helper.get_milestone(repository, milestone_title)

        UI.user_error!("Milestone #{milestone_title} not found.") if milestone.nil?

        github_helper.update_milestone(repository:, number: milestone[:number], state: 'closed')
      end

      def self.description
        'Closes an existing milestone in the project'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        'Closes an existing milestone in the project'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       env_name: 'GHHELPER_REPOSITORY',
                                       description: 'The remote path of the GH repository on which we work',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :milestone,
                                       env_name: 'GHHELPER_MILESTONE',
                                       description: 'The GitHub milestone',
                                       optional: false,
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
