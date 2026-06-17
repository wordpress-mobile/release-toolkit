# frozen_string_literal: true

require 'fastlane/action'
require 'nokogiri'

module Fastlane
  module Actions
    class AndroidPruneOrphanedTranslationsAction < Action
      def self.run(params)
        res_dir = params[:res_dir]
        source_paths = [File.join(res_dir, 'values', 'strings.xml')] + params[:additional_source_strings_paths]
        valid_keys = collect_keys(source_paths)

        locale_files = Dir.glob(File.join(res_dir, 'values-*', 'strings.xml'))
        total_pruned = 0

        locale_files.each do |file|
          pruned = prune_file(file: file, valid_keys: valid_keys)
          next if pruned.empty?

          total_pruned += pruned.count
          UI.message("Pruned #{pruned.count} orphaned entries from `#{file}`: #{pruned.join(', ')}")
        end

        UI.success("Pruned #{total_pruned} orphaned translation entries across #{locale_files.count} locale file(s).")
        total_pruned
      end

      # Collects the set of resource names (string, string-array, plurals, …) declared in the given strings files.
      #
      # @param [Array<String>] paths The strings.xml files to read the valid keys from.
      # @return [Set<String>] The set of declared resource names.
      def self.collect_keys(paths)
        paths.each_with_object(Set.new) do |path, keys|
          doc = File.open(path) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
          doc.xpath('/resources/*[@name]').each { |node| keys << node['name'] }
        end
      end

      # Removes from `file` any resource entry whose `name` is not in `valid_keys`, preserving the rest of the
      # file's formatting (so the change shows up as a minimal diff).
      #
      # @param [String] file The locale strings.xml file to prune.
      # @param [Set<String>] valid_keys The set of names that are allowed to remain.
      # @return [Array<String>] The names of the entries that were pruned.
      def self.prune_file(file:, valid_keys:)
        doc = File.open(file) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
        orphans = doc.xpath('/resources/*[@name]').reject { |node| valid_keys.include?(node['name']) }
        return [] if orphans.empty?

        names = orphans.map { |node| node['name'] }
        orphans.each do |node|
          # Drop the indentation/newline text node right before the element too, to avoid leaving a blank line.
          previous = node.previous_sibling
          previous.remove if previous&.text? && previous.text.strip.empty?
          node.remove
        end

        File.open(file, 'w') { |f| doc.write_to(f, encoding: Encoding::UTF_8.to_s, indent: 4) }
        names
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        'Removes translations whose key is not present in the source strings, to avoid Lint `ExtraTranslation` errors'
      end

      def self.details
        <<~DETAILS
          When downloading translations from GlotPress, the export may include keys that are no longer present in
          the app's source strings (e.g. removed or renamed since the GlotPress source was last synced). Android
          Lint flags these orphaned translations as `ExtraTranslation` errors.

          This action removes — from every `values-*/strings.xml` under `res_dir` — any `<string>`, `<string-array>`
          or `<plurals>` entry whose `name` is not declared in the default `values/strings.xml` of `res_dir`,
          optionally unioned with `additional_source_strings_paths` (useful when a product flavor overlays a base
          module's resources at build time, so the base module's keys are valid too).
        DETAILS
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :res_dir,
            description: "Path to the Android project's `res` directory containing the `values-*` locale subdirectories to prune",
            type: String,
            optional: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :additional_source_strings_paths,
            description: 'Paths to additional default `strings.xml` files whose keys should also be treated as valid ' \
                         '(e.g. a base module that the pruned `res_dir` overlays at build time)',
            type: Array,
            optional: true,
            default_value: []
          ),
        ]
      end

      def self.return_value
        'The total number of orphaned translation entries that were pruned'
      end

      def self.authors
        ['Automattic']
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
