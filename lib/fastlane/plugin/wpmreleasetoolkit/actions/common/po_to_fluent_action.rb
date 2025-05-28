# frozen_string_literal: true

require 'poparser'

module Fastlane
  module Actions
    class PoToFluentAction < Action
      def self.run(params)
        require_relative '../../helper/fluent_localization_helper'

        UI.message('Converting PO file to Fluent format...')

        input_path = File.expand_path(params[:input_file])
        output_path = File.expand_path(params[:output_file])

        UI.user_error!("Input file does not exist: #{input_path}") unless File.exist?(input_path)

        # Parse the PO file
        po_entries = Helper::FluentLocalizationHelper.parse_po_file(input_path)
        UI.message("Found #{po_entries.length} translated entries in PO file")

        # Convert to Fluent format
        fluent_content = Helper::FluentLocalizationHelper.po_to_fluent(po_entries)

        # Write the Fluent file
        File.write(output_path, fluent_content, encoding: 'utf-8')

        UI.success("Successfully converted PO file to Fluent: #{output_path}")
        output_path
      end

      def self.description
        'Convert PO (.po) files to Fluent (.ftl) format after translation'
      end

      def self.authors
        ['Automattic']
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :input_file,
            env_name: 'PO_TO_FLUENT_INPUT_FILE',
            description: 'Path to the input PO (.po) file',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :output_file,
            env_name: 'PO_TO_FLUENT_OUTPUT_FILE',
            description: 'Path to the output Fluent (.ftl) file',
            optional: false,
            type: String
          ),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
