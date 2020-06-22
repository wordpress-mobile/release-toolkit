require 'fastlane/action'
require 'date'
require_relative '../../helper/ghhelper_helper'
require_relative '../../helper/ios/ios_version_helper'
module Fastlane
  module Actions
    class IosMergeTranslatorsStringsAction < Action
      def self.run(params)
        folder_path = File.expand_path(params[:strings_folder])

        subfolders = Dir.entries("#{folder_path}")
        subfolders.each do | strings_folder |
          merge_folder(File.join(folder_path, strings_folder)) if strings_folder.ends_with?(".lproj")
        end
      end

      def self.merge_folder(strings_folder)
        main_file = File.join(strings_folder, "Localizable.strings")
        tmp_main_file = File.join(strings_folder, "Localizable_current.strings")
        return unless (File.exist?(main_file) && File.exist?(tmp_main_file))

        UI.message("Merging in: #{strings_folder}")

        join_files = Dir.glob(File.join("#{strings_folder}", "Localizable_*.strings")) - [tmp_main_file]
        extra_strings = Array.new
        extra_keys = Array.new
        join_files.each do | join_strings |
          my_strings = File.read(join_strings).split("\n")
          my_strings.each do | string | 
            if string[/^\"(.*)\" = \"(.*)\";$/] 
              /^\"(?<string_key>.*)\" = \"/i =~ string
              if (!extra_keys.include?(string_key))
                extra_strings << string 
                extra_keys << string_key
              end
            end
          end

          File.delete(join_strings)
        end

        File.open(main_file, "w") do | f | 
          File.open(tmp_main_file).each do | line |
            f.puts(check_line(line, extra_keys))
          end
          f.puts(extra_strings)
        end

        File.delete(tmp_main_file)
      end

      def self.check_line(line, extra_keys)
        return line unless (line[/^\"(.*)\" = \"(.*)\";$/])
        
        /^\"(?<line_key>.*)\" = \"/i =~ line
        return "" if (extra_keys.include?(line_key))

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
                                   env_name: "IMTS_STRING_FOLDER",
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
