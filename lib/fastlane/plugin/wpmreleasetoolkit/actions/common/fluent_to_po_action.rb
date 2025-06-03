# frozen_string_literal: true

require 'gettext'
require 'gettext/po_parser'
require 'gettext/po'
require 'twitter_cldr'

module Fastlane
  module Actions
    class FluentToPoAction < Action
      def self.run(params)
        require_relative '../../helper/fluent_localization_helper'

        UI.message('Converting Fluent file to PO format...')

        input_path = File.expand_path(params[:input_file])
        output_path = File.expand_path(params[:output_file])

        UI.user_error!("Input file does not exist: #{input_path}") unless File.exist?(input_path)

        # Parse the Fluent file
        fluent_entries = Helper::FluentLocalizationHelper.parse_fluent_file(input_path)
        UI.message("Found #{fluent_entries.length} entries in Fluent file")

        # Convert to PO format
        po_content = Helper::FluentLocalizationHelper.fluent_to_po(
          fluent_file: File.basename(input_path),
          fluent_entries: fluent_entries,
          locale: params[:locale],
          project_name: params[:project_name],
          project_version: params[:project_version]
        )

        File.write(output_path, po_content, encoding: 'utf-8')

        UI.success("Successfully converted Fluent file to PO: #{output_path}")

        output_path
      end

      def self.description
        'Convert Fluent (.ftl) files to PO (.po) format for GlotPress integration'
      end

      def self.authors
        ['Automattic']
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :input_file,
            description: 'Path to the input Fluent (.ftl) file',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :output_file,
            description: 'Path to the output PO (.po) file',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :locale,
            description: 'Target locale (e.g., en-US, es-ES)',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :project_name,
            description: 'Project name for the PO header',
            optional: true,
            type: String,
            default_value: ''
          ),
          FastlaneCore::ConfigItem.new(
            key: :project_version,
            description: 'Project version for the PO header',
            optional: true,
            type: String,
            default_value: ''
          ),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
