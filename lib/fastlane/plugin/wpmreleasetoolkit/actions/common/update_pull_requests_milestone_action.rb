require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class UpdatePullRequestsMilestoneAction < Action
      def self.run(params)
        repository = params[:repository]

        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])

        pr_numbers = params[:pr_numbers]
        from_milestone = params[:from_milestone]
        to_milestone = params[:to_milestone]
        pr_comment = params[:pr_comment]

        target_milestone = nil
        unless to_milestone.nil?
          target_milestone = github_helper.get_milestone(repository, to_milestone)
          UI.user_error!("Unable to find target milestone matching version #{to_milestone}") if target_milestone.nil?
        end

        prs_nums = if pr_numbers
                     pr_numbers
                   elsif from_milestone
                     # get the milestone object based on title starting text
                     m = github_helper.get_milestone(repository, from_milestone)
                     UI.user_error!("Unable to find source milestone matching version #{from_milestone}") if m.nil?

                     # get all open PRs in that milestone
                     github_helper.get_prs_for_milestone(repository: repository, milestone: m).map(&:number)
                   else
                     UI.user_error!('One of `pr_numbers` or `from_milestone` must be provided to indicate which PR(s) to update')
                   end

        UI.message("Updating milestone of #{prs_nums.count} PRs to `#{target_milestone&.title}`")

        prs_nums.each do |pr_num|
          github_helper.set_pr_milestone(
            repository: repository,
            pr_number: pr_num,
            milestone: target_milestone
          )
          next if pr_comment.nil? || pr_comment.empty?

          github_helper.comment_on_pr(
            project_slug: repository,
            pr_number: pr_num,
            body: pr_comment
          )
        end
      end

      def self.description
        'Updates the milestone field of PRs'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'The PR numbers of all the PRs that were updated with the new milestone'
      end

      def self.details
        'Updates the milestone field of a PR, of or all still-opened PRs in a milestone'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       env_name: 'GHHELPER_REPOSITORY',
                                       description: 'The remote path of the GH repository on which we work',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :pr_numbers,
                                       description: 'The PR numbers to update the milestone of, if we only want to update a single PR',
                                       optional: true,
                                       type: Array,
                                       conflicting_options: [:from_milestone]),
          FastlaneCore::ConfigItem.new(key: :from_milestone,
                                       description: 'The version (milestone title\'s start) for which we want to update all open PRs of to a new milestone',
                                       optional: true,
                                       type: String,
                                       conflicting_options: [:pr_numbers]),
          FastlaneCore::ConfigItem.new(key: :to_milestone,
                                       description: 'The version (milestone title\'s start) for the new milestone to assign to the targeted PRs. Pass nil to unset the milestone',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :pr_comment,
                                       description: 'If non-nil, the custom comment to leave on each PR whose milestone has been updated',
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
