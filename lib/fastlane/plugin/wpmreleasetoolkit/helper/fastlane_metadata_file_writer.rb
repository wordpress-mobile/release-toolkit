require 'fastlane_core/ui/ui'
require 'fileutils'

module Fastlane
  module Helper
    module MetadataFilesWriter

      # @note If the translation for `key` exceeds the specified `max_len`, we will try to find an alternate key named `#{key}_short` by convention.
      MetadataRule = Struct.new(:key, :max_len, :filename) do
        def self.android_rules(version_name:, version_code:)
          suffix = version_name.gsub('.', '')
          [
            MetadataRule.new("release_note_#{suffix}", 500, File.join('changelogs', "#{version_code}.txt")),
            MetadataRule.new('play_store_app_title', 30, 'title.txt'),
            MetadataRule.new('play_store_promo', 80, 'short_description.txt'),
            MetadataRule.new('play_store_desc', 4000, 'full_description.txt'),
          ]
        end

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

      def self.write(locale_dir:, io:, rules:, &rule_for_unknown_key)
        self.process_json(io: io, rules: rules, rule_for_unknown_key: rule_for_unknown_key) do |_key, rule, value|
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
