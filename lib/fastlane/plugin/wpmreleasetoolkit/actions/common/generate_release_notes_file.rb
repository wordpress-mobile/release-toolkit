# frozen_string_literal: true

require 'fastlane/action'
require_relative 'get_prs_between_tags'
require_relative '../../helper/release_notes_helper'

module Fastlane
  module Actions
    class GenerateReleaseNotesFileAction < Action
      def self.run(params)
        UI.user_error!('An explicit previous_tag is required to generate release notes') if params[:previous_tag].to_s.empty?
        version = params[:version]
        UI.user_error!('Expected a numeric release version') unless version.match?(/\A\d+(?:\.\d+){0,2}\z/)

        path = params[:release_notes_file_path]
        contents = File.read(path)
        options = params.values.except(:version, :release_notes_file_path, :dry_run)
        markdown = other_action.get_prs_between_tags(**options, fail_on_error: true)
        section = "#{version}\n-----\n#{markdown.rstrip}\n\n"
        updated = Helper::ReleaseNotesHelper.update_section(contents: contents, version: version, section: section)

        if params[:dry_run]
          UI.message(section)
        else
          File.write(path, updated)
        end
        section
      end

      def self.description
        'Write generated GitHub Markdown to a RELEASE-NOTES.txt version section'
      end

      def self.details
        <<~DETAILS
          Inserts or replaces one version section using get_prs_between_tags, preserving other versions and header comments.
          Keeps the returned Markdown, including headings, authors, contributors, and links.
          Use configuration_file_path to exclude or group PRs by GitHub labels; no title markers are needed.
          For a separate report, such as release testing, call get_prs_between_tags with its own configuration_file_path.
          Requires an explicit previous_tag and a published target_commitish if tag_name does not exist.
          Use dry_run to preview without writing. Does not commit changes.
        DETAILS
      end

      def self.available_options
        GetPrsBetweenTagsAction.available_options.reject { |option| option.key == :fail_on_error } + [
          FastlaneCore::ConfigItem.new(key: :version, description: 'Numeric version heading in RELEASE-NOTES.txt', type: String),
          FastlaneCore::ConfigItem.new(key: :release_notes_file_path, description: 'Existing release notes file', type: String, default_value: 'RELEASE-NOTES.txt'),
          FastlaneCore::ConfigItem.new(key: :dry_run, description: 'Preview the section without writing the file', type: Boolean, default_value: false),
        ]
      end

      def self.return_value
        'The generated version section'
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
