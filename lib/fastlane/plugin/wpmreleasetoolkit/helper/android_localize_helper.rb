require 'fastlane_core/ui/ui'
require 'fileutils'
require 'nokogiri'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class AndroidLocalizeHelper
      # Checks if string_line has the content_override flag set
      def self.skip_string_by_tag(string_line)
        skip = string_line.attr("content_override") == "true" unless string_line.attr("content_override").nil?
        if (skip)
          puts " - Skipping #{string_line.attr("name")} string"
          return true
        end

        return false
      end

      # Checks if string_name is in the excluesion list
      def self.skip_string_by_exclusion_list(library, string_name)
        if (!library.key?(:exclusions))
          return false
        end

        skip = library[:exclusions].include?(string_name)
        if (skip)
          puts " - Skipping #{string_name} string"
          return true
        end
      end

      # Merge string_line into main_string
      def self.merge_string(main_strings, library, string_line)
        string_name = string_line.attr("name")
        string_content = string_line.content

        # Skip strings in the exclusions list
        return :skipped if skip_string_by_exclusion_list(library, string_name)

        # Search for the string in the main file
        main_strings.xpath('//string').each do |this_string|
          if (this_string.attr("name") == string_name) then
            # Skip if the string has the content_override tag
            return :skipped if skip_string_by_tag(this_string)

            # Update if needed
            (if (this_string.content == string_content) then return :found else this_string.content = string_content; return :updated end)
          end
        end

        # String not found and not in the exclusion list: add to the main file
        new_element = Nokogiri::XML::Node.new "string", main_strings
        new_element['name'] = string_name
        new_element.content = string_content
        main_strings.xpath('//string').last().add_next_sibling("\n#{" " * 4}#{new_element.to_xml()}")
        return :added
      end

      # Verify a string
      def self.verifystring(main_strings, library, string_line)
        string_name = string_line.attr("name")
        string_content = string_line.content

        # Skip strings in the exclusions list
        return if skip_string_by_exclusion_list(library, string_name)

        # Search for the string in the main file
        main_strings.xpath('//string').each do |this_string|
          if (this_string.attr("name") == string_name) then
            # Skip if the string has the content_override tag
            return if skip_string_by_tag(this_string)

            # Update if needed
            UI.user_error!("String #{string_name} [#{string_content}] has been updated in the main file but not in the library #{library[:library]}.") if (this_string.content != string_content)
            return
          end
        end

        # String not found and not in the exclusion list:
        UI.user_error!("String #{string_name} [#{string_content}] was found in library #{library[:library]} but not in the main file.")
      end

      def self.merge_lib(main, library)
        UI.message("Merging #{library[:library]} strings into #{main}")
        main_strings = File.open(main) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
        lib_strings = File.open(library[:strings_path]) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }

        updated_count = 0
        untouched_count = 0
        added_count = 0
        skipped_count = 0
        lib_strings.xpath('//string').each do |string_line|
          res = merge_string(main_strings, library, string_line)
          case res
          when :updated
            puts "#{string_line.attr("name")} updated."
            updated_count = updated_count + 1
          when :found
            untouched_count = untouched_count + 1
          when :added
            puts "#{string_line.attr("name")} added."
            added_count = added_count + 1
          when :skipped
            skipped_count = skipped_count + 1
          else
            UI.user_error!("Internal Error! #{res}")
            end
        end

        File.open(main, "w:UTF-8") do |f|
          f.write(main_strings.to_xml(:indent => 4))
        end

        UI.message("Done (#{added_count} added, #{updated_count} updated, #{untouched_count} untouched, #{skipped_count} skipped).")
        return (added_count + updated_count) != 0
      end

      def self.verify_diff(diff_string, main_strings, lib_strings, library)
        if diff_string.start_with?("name=") then
          diff_string.slice!('name="')

          end_index = diff_string.index('"')
          end_index ||= diff_string.length # Use the whole string if there's no '"'

          diff_string = diff_string.slice(0..(end_index - 1))

          lib_strings.xpath('//string').each do |string_line|
            if (string_line.attr("name") == diff_string) then
              res = verifystring(main_strings, library, string_line)
            end
          end
        end
      end

      def self.verify_lib(main, library, source_diff)
        UI.message("Checking #{library[:library]} strings vs #{main}")
        main_strings = File.open(main) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
        lib_strings = File.open(library[:strings_path]) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }

        verify_local_diff(main, library, main_strings, lib_strings)
        verify_pr_diff(main, library, main_strings, lib_strings, source_diff) unless source_diff.nil?
      end

      def self.verify_local_diff(main, library, main_strings, lib_strings)
        `git diff #{main}`.each_line do |line|
          if (line.start_with?("+ ") or line.start_with?("- ")) then
            diffs = line.gsub(/\s+/m, ' ').strip.split(" ")
            diffs.each do |diff|
              verify_diff(diff, main_strings, lib_strings, library)
            end
          end
        end
      end

      def self.verify_pr_diff(main, library, main_strings, lib_strings, source_diff)
        source_diff.each_line do |line|
          if (line.start_with?("+ ") or line.start_with?("- ")) then
            diffs = line.gsub(/\s+/m, ' ').strip.split(" ")
            diffs.each do |diff|
              verify_diff(diff, main_strings, lib_strings, library)
            end
          end
        end
      end
    end
  end
end
