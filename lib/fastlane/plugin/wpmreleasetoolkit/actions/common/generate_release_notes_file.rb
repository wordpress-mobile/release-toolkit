# frozen_string_literal: true

require 'fastlane/action'
require_relative 'get_prs_between_tags'
require_relative '../../helper/generated_release_notes_helper'

module Fastlane
  module Actions
    class GenerateReleaseNotesFileAction < Action
      def self.run(params)
        UI.user_error!('An explicit previous_tag is required to generate release notes') if params[:previous_tag].to_s.empty?

        path = params[:release_notes_file_path]
        contents = File.read(path)
        options = GetPrsBetweenTagsAction.available_options.reject { |option| option.key == :fail_on_error }.to_h { |option| [option.key, params[option.key]] }
        markdown = other_action.get_prs_between_tags(**options, fail_on_error: true)
        helper = Helper::GeneratedReleaseNotesHelper
        section = helper.section(version: params[:version], markdown: markdown)
        updated = helper.update(contents: contents, version: params[:version], section: section)

        if params[:dry_run]
          UI.message(section)
        else
          File.write(path, updated)
        end
        section
      end

      def self.description
        'Generate a RELEASE-NOTES.txt version section from merged PR titles'
      end

      def self.details
        <<~DETAILS
          Uses get_prs_between_tags and GitHub's release notes configuration to select PRs.
          Replaces the requested version's section, or inserts it before existing versions, preserving history and header comments.
          Entries use `- [*] Title [PR URL]`; explicit priority stars at the start of a title are preserved.
          Requires an explicit previous_tag. Use a published target_commitish when tag_name does not exist yet.
          API errors and unrecognized change entries fail without writing. Does not commit changes.
          dry_run prints and returns the proposed section without changing the file.
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
