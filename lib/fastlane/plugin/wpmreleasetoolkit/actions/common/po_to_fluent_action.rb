# frozen_string_literal: true

require 'gettext'
require 'gettext/po_parser'
require 'gettext/po'

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

        # Convert to Fluent format
        fluent_content = Helper::FluentLocalizationHelper.po_to_fluent(po_entries)

        if !params[:allow_empty_file] && fluent_content.strip.empty?
          UI.message('No translated content found in PO file')
          return
        end

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
            description: 'Path to the input PO (.po) file',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :output_file,
            description: 'Path to the output Fluent (.ftl) file',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :allow_empty_file,
            description: 'Whether to allow an empty file when no translated content is found',
            optional: true,
            type: Boolean,
            default_value: false
          ),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
