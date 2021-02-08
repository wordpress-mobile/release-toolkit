require 'fastlane/action'
require 'date'
require_relative '../../helper/github_helper'
require_relative '../../helper/ios/ios_version_helper'
require_relative '../../helper/android/android_version_helper'
module Fastlane
  module Actions
    class AndroidMergeTranslatorsStringsAction < Action
      def self.run(params)
        folder_path = File.expand_path(params[:strings_folder])

        subfolders = Dir.entries("#{folder_path}")
        subfolders.each do |strings_folder|
          merge_folder(File.join(folder_path, strings_folder)) if strings_folder.start_with?("values")
        end
      end

      def self.merge_folder(strings_folder)
        main_file = File.join(strings_folder, "strings.xml")
        return unless File.exist?(main_file)

        UI.message("Merging in: #{strings_folder}")

        tmp_main_file = main_file + ".tmp"
        FileUtils.cp(main_file, tmp_main_file)

        join_files = Dir.glob(File.join("#{strings_folder}", "strings-*.xml"))
        extra_strings = Array.new
        extra_keys = Array.new
        join_files.each do |join_strings|
          my_strings = File.read(join_strings).split("\n")
          my_strings.each do |string|
            if string.include?("<string name")
              string_key = string.strip.split(">").first
              if (!extra_keys.include?(string_key))
                extra_strings << string
                extra_keys << string_key
              end
            end
          end

          File.delete(join_strings)
        end

        File.open(main_file, "w") do |f|
          File.open(tmp_main_file).each do |line|
            f.puts(extra_strings) if (line.strip == "</resources>")
            f.puts(check_line(line, extra_strings))
          end
        end

        File.delete(tmp_main_file)
      end

      def self.check_line(line, extra_strings)
        return line unless (line.include?("<string name"))

        test_line = line.strip.split(">").first
        extra_strings.each do |overwrite_string|
          if (overwrite_string.strip.split(">").first == test_line) then
            return ""
          end
        end

        return line
      end

      def self.description
        "Merge strings for translators"
      end

      def self.authors
        ["Lorenzo Mattei"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Merges waiting and fuzzy strings into the main file for translators"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :strings_folder,
                                   env_name: "AMTS_STRING_FOLDER",
                                description: "The folder that contains all the translations",
                                   optional: false,
                                       type: String),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
