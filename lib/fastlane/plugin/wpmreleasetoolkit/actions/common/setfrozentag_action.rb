require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class SetfrozentagAction < Action
      def self.run(params)
        repository = params[:repository]
        milestone_title = params[:milestone]
        freeze = params[:freeze]

        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])
        milestone = github_helper.get_milestone(repository, milestone_title)

        UI.user_error!("Milestone #{milestone_title} not found.") if milestone.nil?

        mile_title = milestone[:title]
        puts freeze
        if freeze
          # Check if the state needs changes
          if is_frozen(milestone)
            UI.message("Milestone #{mile_title} is already frozen. Nothing to do")
            return # Already frozen: nothing to do
          end

          mile_title = "#{mile_title} ❄️"
        else
          mile_title = milestone_title
        end

        UI.message("New milestone: #{mile_title}")
        github_helper.update_milestone(repository: repository, number: milestone[:number], title: mile_title)
      end

      def self.is_frozen(milestone)
        return milestone[:title].include?('❄️') unless milestone.nil?

        return false
      end

      def self.description
        'Sets the frozen tag for the specified milestone'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        'Sets the frozen tag for the specified milestone'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       env_name: 'GHHELPER_REPOSITORY',
                                       description: 'The remote path of the GH repository on which we work',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :milestone,
                                       env_name: 'GHHELPER_MILESTORE',
                                       description: 'The GitHub milestone',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :freeze,
                                       description: 'If true, the action will add the ❄️ emoji to the milestone title',
                                       optional: false,
                                       default_value: true,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :github_api_token,
                                       description: 'The GitHub OAuth access token',
                                       optional: true,
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
