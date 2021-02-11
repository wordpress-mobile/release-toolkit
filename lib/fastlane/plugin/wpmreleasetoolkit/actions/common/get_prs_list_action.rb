require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class GetPrsListAction < Action
      def self.run(params)
        repository = params[:repository]
        start_tag = params[:start_tag]
        end_tag = params[:end_tag]
        report_path = params[:report_path]

        # Get commit list
        commit_list = sh("git log --pretty=oneline #{start_tag}..#{end_tag}")

        # Extract PRs
        pr_list = []
        commit_list.split("\n").each do |commit|
          if (commit.include?('Merge pull request #'))
            # PR found, so extract PR number
            pr_list.push(commit.partition('#').last.split(' ')[0])
          end
        end

        # Get infos from GitHub and put into the target file
        client = Fastlane::Helper::GithubHelper.github_client()
        File.open(report_path, 'w') do |file|
          pr_list.each do |pr_number|
            begin
              data = client.pull_request(repository, pr_number.to_i)
              file.puts("##{data[:number]}: #{data[:title]} @#{data[:user][:login]} #{data[:html_url]}")
            rescue
              UI.message("Could not find a PR with number #{pr_number.to_i}. Usually this is due to a bad reference in a commit message, but you probably want to check.")
            end
          end
        end
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
          FastlaneCore::ConfigItem.new(key: :start_tag,
                                description: 'The tag from which the report starts',
                                   optional: false,
                                  is_string: true),
          FastlaneCore::ConfigItem.new(key: :end_tag,
                                 description: 'The tag to which the report ends',
                                    optional: true,
                               default_value: '.',
                                   is_string: true),
          FastlaneCore::ConfigItem.new(key: :report_path,
                                  env_name: 'GHHELPER_REPORTPATH',
                               description: 'The path of the report file',
                                  optional: false,
                                 is_string: true)
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
