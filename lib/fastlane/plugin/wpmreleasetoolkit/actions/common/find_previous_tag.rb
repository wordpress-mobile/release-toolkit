require 'fastlane/action'
require_relative '../../helper/github_helper'

module Fastlane
  module Actions
    class FindPreviousTagAction < Action
      def self.run(params)
        tag_pattern = params[:pattern]

        # Make sure we have all the latest tags fetched locally
        Actions.sh('git', 'fetch', '--tags', '--force') { nil }
        # Check if the current commit has a tag, so we can exclude it and not risk returning the current commit tag instead of really-previous one
        current_commit_tag = Actions.sh('git describe --tags --exact-match 2>/dev/null || true').chomp

        # Finally find the previous tag matching the provided pattern, and that is not the current commit
        git_cmd = %w[git describe --tags --abbrev=0]
        git_cmd += ['--match', tag_pattern] unless tag_pattern.nil?
        git_cmd += ['--exclude', current_commit_tag] unless current_commit_tag.empty?
        Actions.sh(*git_cmd) { |exit_status, stdout, _| exit_status.success? ? stdout.chomp : nil }
      end

      def self.description
        'Use `git describe` to find the previous tag matching a specific pattern'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'The name of the previous tag matching the pattern, or nil if none was found'
      end

      def self.details
        <<~DETAILS
          Uses `git describe --tags --abbrev=0 --match … --exclude …` to find the previous git tag
          reachable from the current commit and that matches a specific naming pattern

          e.g. `find_previous_tag(pattern: '12.3.*.*')`, `find_previous_tag(pattern: '12.3-rc-*')`
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :pattern,
                                       description: 'The _fnmatch_-style pattern to use when searching for the previous tag',
                                       optional: true,
                                       default_value: nil,
                                       type: String),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
