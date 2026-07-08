# frozen_string_literal: true

require 'fastlane/action'
require 'nokogiri'

module Fastlane
  module Actions
    class AndroidPruneOrphanedTranslationsAction < Action
      # Matches an Android `values-<qualifier>` directory whose qualifier is a locale: a 2- or 3-letter language
      # code (`fr`, `kmr`), an optional region (`pt-rBR`, `es-r419`), or a BCP-47 `b+` form (`b+sr+Latn`), so
      # non-locale qualifier dirs (e.g. `values-night`, `values-v21`, `values-land`) are left untouched.
      LOCALE_VALUES_DIR_REGEX = /\Avalues-(?:b\+[a-zA-Z]+(?:\+[a-zA-Z0-9]+)*|[a-z]{2,3}(?:-r(?:[A-Z]{2}|\d{3}))?)\z/

      # Android UI-mode qualifiers, which are never locales:
      # https://developer.android.com/guide/topics/resources/providing-resources#UiModeQualifier
      # `car` is indistinguishable by shape from a 3-letter ISO 639 language code, so `LOCALE_VALUES_DIR_REGEX`
      # would otherwise treat `values-car` as a locale and prune its (valid) car-mode resources. There's no purely
      # syntactic way to tell the two apart, so we exclude the documented UI-mode qualifiers explicitly. (`car` is
      # the only one short enough to currently match the regex; the rest are listed to capture the full set.)
      UI_MODE_QUALIFIERS = %w[car desk television appliance watch vrheadset].freeze

      DEFAULT_SOURCE_STRINGS_FILE_NAME = 'strings.xml'
      DEFAULT_SOURCE_STRINGS_RELATIVE_PATH = File.join('values', DEFAULT_SOURCE_STRINGS_FILE_NAME).freeze

      def self.run(params)
        res_dir = params[:res_dir]
        source_paths = [File.join(res_dir, DEFAULT_SOURCE_STRINGS_RELATIVE_PATH)] + params[:additional_source_strings_paths]
        valid_keys = collect_keys(source_paths)

        locale_files = Dir.glob(File.join(res_dir, 'values-*', DEFAULT_SOURCE_STRINGS_FILE_NAME)).select do |file|
          dir_name = File.basename(File.dirname(file))
          dir_name.match?(LOCALE_VALUES_DIR_REGEX) && !UI_MODE_QUALIFIERS.include?(dir_name.delete_prefix('values-'))
        end
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
        'Removes translations whose keys are not present in the source strings, to avoid Lint `ExtraTranslation` errors'
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
            optional: false,
            verify_block: proc do |value|
              source_path = File.join(value, DEFAULT_SOURCE_STRINGS_RELATIVE_PATH)
              UI.user_error!("Source strings file not found: `#{source_path}`") unless File.file?(source_path)
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :additional_source_strings_paths,
            description: 'Paths to additional default `strings.xml` files whose keys should also be treated as valid ' \
                         '(e.g. a base module that the pruned `res_dir` overlays at build time)',
            type: Array,
            optional: true,
            default_value: [],
            verify_block: proc do |value|
              value.each do |path|
                UI.user_error!("Source strings file not found: `#{path}`") unless File.file?(path)
              end
            end
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
