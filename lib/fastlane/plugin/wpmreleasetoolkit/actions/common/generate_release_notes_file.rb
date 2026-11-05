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
        format = params[:format]
        options = params.values.except(*custom_options.map(&:key))
        markdown = other_action.get_prs_between_tags(**options, fail_on_error: true)
        section = Helper::ReleaseNotesHelper.format_section(version: version, markdown: markdown, format: format)
        updated = Helper::ReleaseNotesHelper.update_section(contents: contents, version: version, section: section, format: format)

        if params[:dry_run]
          UI.message(section)
        else
          File.write(path, updated)
        end
        section
      end

      def self.description
        'Write generated GitHub notes to a release notes or Markdown changelog version section'
      end

      def self.details
        <<~DETAILS
          Inserts or replaces one version section using get_prs_between_tags, preserving other versions and header comments.
          Defaults to the underlined version headings used in RELEASE-NOTES.txt.
          Use format: :changelog and release_notes_file_path: 'CHANGELOG.md' for numeric ## version headings.
          Changelog output nests generated headings beneath the version and preserves Trunk/Unreleased sections.
          The existing file must contain at least one version section in the selected format.
          Keeps authors, contributors, and links. Does not promote Unreleased entries or edit other versions.
          Use configuration_file_path to exclude or group PRs by GitHub labels; no title markers are needed.
          For a separate report, such as release testing, call get_prs_between_tags with its own configuration_file_path.
          Requires an explicit previous_tag and a published target_commitish if tag_name does not exist.
          Use dry_run to preview without writing. Does not commit changes.
        DETAILS
      end

      def self.available_options
        GetPrsBetweenTagsAction.available_options.reject { |option| option.key == :fail_on_error } + custom_options
      end

      def self.custom_options
        [
          FastlaneCore::ConfigItem.new(key: :version, description: 'Numeric version heading in the output file', type: String),
          FastlaneCore::ConfigItem.new(key: :release_notes_file_path, description: 'Existing release notes file', type: String, default_value: 'RELEASE-NOTES.txt'),
          FastlaneCore::ConfigItem.new(key: :format,
                                       description: 'Version section format: :release_notes or :changelog',
                                       type: Symbol,
                                       default_value: :release_notes,
                                       verify_block: proc do |value|
                                         UI.user_error!('format must be :release_notes or :changelog') unless %i[release_notes changelog].include?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :dry_run, description: 'Preview the section without writing the file', type: Boolean, default_value: false),
        ]
      end

      private_class_method :custom_options

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
