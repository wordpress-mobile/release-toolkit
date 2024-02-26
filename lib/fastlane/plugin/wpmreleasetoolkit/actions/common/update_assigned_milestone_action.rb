require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class UpdateAssignedMilestoneAction < Action
      def self.run(params)
        repository = params[:repository]

        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])

        numbers = params[:numbers]
        from_milestone = params[:from_milestone]
        to_milestone = params[:to_milestone]
        comment = params[:comment]

        target_milestone = nil
        unless to_milestone.nil?
          target_milestone = github_helper.get_milestone(repository, to_milestone)
          UI.user_error!("Unable to find target milestone matching version #{to_milestone}") if target_milestone.nil?
        end

        issues_list = if numbers
                        numbers
                      elsif from_milestone
                        # get the milestone object based on title starting text
                        m = github_helper.get_milestone(repository, from_milestone)
                        UI.user_error!("Unable to find source milestone matching version #{from_milestone}") if m.nil?

                        # get all open PRs in that milestone
                        github_helper.get_prs_and_issues_for_milestone(repository: repository, milestone: m).map(&:number)
                      else
                        UI.user_error!('One of `numbers` or `from_milestone` must be provided to indicate which PR(s)/issue(s) to update')
                      end

        UI.message("Updating milestone of #{issues_list.count} PRs/Issues to `#{target_milestone&.title}`")

        issues_list.each do |num|
          github_helper.set_milestone(
            repository: repository,
            number: num,
            milestone: target_milestone
          )
          next if comment.nil? || comment.empty?

          github_helper.comment_on_pr(
            project_slug: repository,
            pr_number: num,
            body: comment
          )
        end
      end

      def self.description
        'Updates the milestone field of GitHub Issues and PRs'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'The numbers of all the PRs and Isses that were updated with the new milestone'
      end

      def self.details
        'Updates the milestone field of a given list of PRs/Issues, or of all still-opened PRs/Issues in a given milestone'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       env_name: 'GHHELPER_REPOSITORY',
                                       description: 'The remote path of the GH repository on which we work',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :numbers,
                                       description: 'The PR and/or issue numbers to update the milestone of',
                                       optional: true,
                                       type: Array,
                                       conflicting_options: [:from_milestone]),
          FastlaneCore::ConfigItem.new(key: :from_milestone,
                                       description: 'The version (milestone title\'s start) for which we want to update all open PRs and issues of to a new milestone',
                                       optional: true,
                                       type: String,
                                       conflicting_options: [:numbers]),
          FastlaneCore::ConfigItem.new(key: :to_milestone,
                                       description: 'The version (milestone title\'s start) for the new milestone to assign to the targeted PRs and issues. Pass nil to unset the milestone',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :comment,
                                       description: 'If non-nil, the custom comment to leave on each PR and issue whose milestone has been updated',
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
