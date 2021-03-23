require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class GetPrsListAction < Action
      def self.run(params)
        repository = params[:repository]
        report_path = File.expand_path(params[:report_path])
        tag = params[:tag]

        # Get commit list
        pr_list = Fastlane::Helper::GithubHelper.get_prs_for_milestone(repository, tag)

        File.open(report_path, 'w') do |file|
          pr_list.each do |data|
            file.puts("##{data[:number]}: #{data[:title]} @#{data[:user][:login]} #{data[:html_url]}")
          end
        end

        UI.success("Found #{pr_list.count} PRs in #{tag} – saved to #{report_path}")
      end

      def self.description
        'Generate the list of the PRs from `start_tag` to `end_tag`'
      end

      def self.authors
        ['Lorenzo Mattei']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        'Generate the list of the PRs from `start_tag` to `end_tag`'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :repository,
                                       env_name: 'GHHELPER_REPOSITORY',
                                       description: 'The remote path of the GH repository on which we work',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :report_path,
                                       env_name: 'GHHELPER_REPORTPATH',
                                       description: 'The path of the report file',
                                       optional: false,
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :milestone,
                                       description: 'The milestone to fetch PRs for',
                                       optional: false,
                                       is_string: true),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
