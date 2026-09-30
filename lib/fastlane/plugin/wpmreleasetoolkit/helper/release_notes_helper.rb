# frozen_string_literal: true

module Fastlane
  module Helper
    module ReleaseNotesHelper
      VERSION_HEADING = /^\d+(?:\.\d+){0,2}\r?\n[-=]+\r?\n/

      # Insert or replace one version, preserving other sections and line endings.
      # @param [String] contents Existing RELEASE-NOTES.txt contents.
      # @param [String] version The section to replace or insert.
      # @param [String] section The generated version section.
      # @return [String] Updated file contents.
      def self.update_section(contents:, version:, section:)
        sections = contents.split(/(?=#{VERSION_HEADING})/)
        versions = sections.map { |part| part.lines.first.chomp if part.match?(VERSION_HEADING) }
        first_version = versions.index { |value| value }
        UI.user_error!('No version headings found in the release notes file') unless first_version
        UI.user_error!("Duplicate release notes sections for #{version}") if versions.count(version) > 1

        newline = contents.include?("\r\n") ? "\r\n" : "\n"
        section = section.gsub(/\r?\n/, newline)
        index = versions.index(version)
        if index
          sections[index] = section
        else
          sections.insert(first_version, section)
        end
        sections.join
      end

      # Update the release notes file (typycally RELEASE-NOTES.txt) to add a new entry.
      #
      # @param [String] path The path to the release notes text file.
      # @param [String] section_title The title of the new section (typically the new version number) to add.
      #
      def self.add_new_section(path:, section_title:)
        lines = File.readlines(path)

        # Find the index of the first non-empty line that is also NOT a comment.
        # That way we keep commment headers as the very top of the file
        line_idx = lines.find_index { |l| !l.start_with?('***') && !l.start_with?('//') && !l.chomp.empty? }
        # Put back the header, then the new entry, then the rest
        # (note: '...' excludes the higher bound of the range, unlike '..')
        new_lines = lines[0...line_idx] + ["#{section_title}\n", "-----\n", "\n", "\n"] + lines[line_idx..]

        File.write(path, new_lines.join)
      end
    end
  end
end
