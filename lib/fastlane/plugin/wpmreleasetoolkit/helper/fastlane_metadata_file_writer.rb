require 'fastlane_core/ui/ui'
require 'fileutils'

module Fastlane
  module Helper
    module FastlaneMetadataFilesWriter

      # A model/struct defining a rule on how to process and map metadata from GlotPress into txt files
      #
      # @param [String] key The key in the GlotPress export for the metadata
      # @param [Int] max_len The maximum length allowed by the App Store / Play Store for that key.
      #        Note: If the translation for `key` exceeds the specified `max_len`, we will try to find an alternate key named `#{key}_short` by convention.
      # @param [String] filename The (relative) path to the `.txt` file to write that metadata to
      #
      MetadataRule = Struct.new(:key, :max_len, :filename) do
        # The common standardized set of Metadata rules for an Android project
        def self.android_rules(version_name:, version_code:)
          suffix = version_name.gsub('.', '')
          [
            MetadataRule.new("release_note_#{suffix}", 500, File.join('changelogs', "#{version_code}.txt")),
            MetadataRule.new('play_store_app_title', 30, 'title.txt'),
            MetadataRule.new('play_store_promo', 80, 'short_description.txt'),
            MetadataRule.new('play_store_desc', 4000, 'full_description.txt'),
          ]
        end

        # The common standardized set of Metadata rules for an Android project
        def self.ios_rules(version_name:)
          suffix = version_name.gsub('.', '')
          [
            MetadataRule.new("release_note_#{suffix}", 4000, 'release_notes.txt'),
            MetadataRule.new('app_store_name', 30, 'name.txt'),
            MetadataRule.new('app_store_subtitle', 30, 'subtitle.txt'),
            MetadataRule.new('app_store_description', 4000, 'description.txt'),
            MetadataRule.new('app_store_keywords', 100, 'keywords.txt'),
          ]
        end
      end

      # Visit each key/value pair of a translations Hash, and yield keys and matching translations from it based on the passed `MetadataRules`,
      # trying any potential fallback key if the translation exceeds the max limit, and yielding each found and valid entry to the caller.
      #
      # @param [#read] io
      # @param [Array<MetadataRule>] rules List of rules for each key
      # @param [Block] rule_for_unknown_key An optional block called when a key that does not match any of the rules is encountered.
      #        The block will receive a [String] (key) and must return a `MetadataRule` instance (or nil)
      #
      # @yield [String, MetadataRule, String] yield each (key, matching_rule, value) tuple found in the JSON, after resolving alternates for values exceeding max length
      #        Note that if both translations for the key and its (optional) shorter alternate exceeds the max_len, it will still `yield` but with a `nil` value
      #
      def self.visit(translations:, rules:, rule_for_unknown_key:)
        translations.each do |key, value|
          next if key.nil? || key.end_with?('_short') # skip if alternate key

          rule = rules.find { |r| r.key == key }
          rule = rule_for_unknown_key.call(key) if rule.nil? && !rule_for_unknown_key.nil?
          next if rule.nil?

          if rule.max_len != nil && value.length > rule.max_len
            UI.warning "Translation for #{key} is too long (#{value.length}), trying shorter alternate #{key}."
            short_key = "#{key}_short"
            value = json[short_key]
            if value.nil?
              UI.warning "No shorter alternate (#{short_key}) available, skipping entirely."
              yield key, rule, nil
              next
            end
            if value.length > rule.max_len
              UI.warning "Translation alternate for #{short_key} was too long too (#{value.length}), skipping entirely."
              yield short_key, rule, nil
              next
            end
          end
          yield key, rule, value
        end
      end

      # Write the `.txt` files to disk for the given exported translation file (typically a JSON export) based on the `MetadataRules` provided
      #
      # @param [String] locale_dir the path to the locale directory (e.g. `fastlane/metadata/android/fr`) to write the `.txt` files to
      # @param [Hash<String,String>] translations The hash of translations (key => translation) to visit based on `MetadataRules` then write to disk.
      # @param [Array<MetadaataRule>] rules The list of fixed `MetadataRule` to use to extract the expected metadata from the `translations`
      # @param [Block] rule_for_unknown_key An optional block called when a key that does not match any of the rules is encountered.
      #        The block will receive a [String] (key) and must return a `MetadataRule` instance (or nil)
      #
      def self.write(locale_dir:, translations:, rules:, &rule_for_unknown_key)
        self.visit(translations: translations, rules: rules, rule_for_unknown_key: rule_for_unknown_key) do |_key, rule, value|
          dest = File.join(locale_dir, rule.filename)
          if value.nil? && File.exist?(dest)
            # Key found in JSON was rejected for being too long. Delete file
            UI.verbose("Deleting file #{dest}")
            FileUtils.rm(dest)
          elsif value
            UI.verbose("Writing file #{dest}")
            FileUtils.mkdir_p(File.dirname(dest))
            File.write(dest, value.chomp)
          end
        end
      end
    end
  end
end
