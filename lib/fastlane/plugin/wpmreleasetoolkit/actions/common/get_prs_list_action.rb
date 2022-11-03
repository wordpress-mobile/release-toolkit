require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class GetPrsListAction < Action
      def self.run(params)
        repository = params[:repository]
        report_path = File.expand_path(params[:report_path])
        milestone = params[:milestone]

        # Get commit list
        github_helper = Fastlane::Helper::GithubHelper.new(github_token: params[:github_token])
        pr_list = github_helper.get_prs_for_milestone(repository, milestone)

        File.open(report_path, 'w') do |file|
          pr_list.each do |data|
            file.puts("##{data[:number]}: #{data[:title]} @#{data[:user][:login]} #{data[:html_url]}")
          end
        end

        UI.success("Found #{pr_list.count} PRs in #{milestone} – saved to #{report_path}")
      end

      def self.description
        'Generate the list of the PRs in the given `repository` for the given `milestone` at the given `report_path`'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        description
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       env_name: 'GHHELPER_REPOSITORY',
                                       description: 'The repository name, including the organization (e.g. `wordpress-mobile/wordpress-ios`)',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :report_path,
                                       description: 'The path where the list of PRs should be written to',
                                       optional: false,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :milestone,
                                       description: 'The name of the milestone we want to fetch the list of PRs for (e.g.: `16.9`)',
                                       optional: false,
                                       is_string: true),
          Fastlane::Helper::GithubHelper.github_token_config_item,
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
