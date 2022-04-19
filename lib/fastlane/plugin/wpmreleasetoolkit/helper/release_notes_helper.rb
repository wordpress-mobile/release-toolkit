module Fastlane
  module Helper
    module ReleaseNotesHelper
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
