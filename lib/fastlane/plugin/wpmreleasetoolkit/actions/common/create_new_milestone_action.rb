require 'fastlane/action'
require 'date'
require_relative '../../helper/github_helper'
require_relative '../../helper/ios/ios_version_helper'
require_relative '../../helper/android/android_version_helper'
module Fastlane
  module Actions
    class CreateNewMilestoneAction < Action
      def self.run(params)
        repository = params[:repository]

        last_stone = Fastlane::Helper::GithubHelper.get_last_milestone(repository)
        UI.message("Last detected milestone: #{last_stone[:title]} due on #{last_stone[:due_on]}.")
        milestone_duedate = last_stone[:due_on]
        newmilestone_duration = params[:milestone_duration]
        newmilestone_duedate = (milestone_duedate.to_datetime.next_day(newmilestone_duration).to_time).utc
        newmilestone_number = Fastlane::Helper::Ios::VersionHelper.calc_next_release_version(last_stone[:title])
        UI.message("Next milestone: #{newmilestone_number} due on #{newmilestone_duedate}.")
        Fastlane::Helper::GithubHelper.create_milestone(repository, newmilestone_number, newmilestone_duedate, newmilestone_duration, params[:need_appstore_submission])
      end

      def self.description
        'Creates a new milestone for the project'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        'Creates a new milestone for the project'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       env_name: 'GHHELPER_REPOSITORY',
                                       description: 'The remote path of the GH repository on which we work',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :need_appstore_submission,
                                       env_name: 'GHHELPER_NEED_APPSTORE_SUBMISSION',
                                       description: 'True if the app needs to be submitted',
                                       optional: true,
                                       is_string: false,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :milestone_duration,
                                       env_name: 'GHHELPER_MILESTONE_DURATION',
                                       description: 'Milestone duration in number of days',
                                       optional: true,
                                       is_string: false,
                                       default_value: 14),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
