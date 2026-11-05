# frozen_string_literal: true

module Fastlane
  module Helper
    module ReleaseNotesHelper
      VERSION_HEADING = /^\d+(?:\.\d+){0,2}\r?\n[-=]+\r?\n/

      # Render a version section, nesting generated Markdown headings in changelog output.
      def self.format_section(version:, markdown:, format: :release_notes)
        return "#{version}\n-----\n#{markdown.rstrip}\n\n" unless format == :changelog

        headings = markdown_headings(markdown)
        shift = [3 - (headings.map(&:last).min || 3), 0].max
        markdown = markdown.dup
        headings.reverse_each do |offset, level|
          markdown.insert(markdown.index('#', offset), '#' * [shift, 6 - level].min)
        end
        "## #{version}\n\n#{markdown.rstrip}\n\n"
      end

      # Insert or replace one version, preserving other sections and line endings.
      # @param [String] contents Existing release notes or changelog contents.
      # @param [String] version The section to replace or insert.
      # @param [String] section The generated version section.
      # @param [Symbol] format Version heading format: :release_notes or :changelog.
      # @return [String] Updated file contents.
      def self.update_section(contents:, version:, section:, format: :release_notes)
        if format == :changelog
          offsets = markdown_headings(contents).select { |_, level| level <= 2 }.map(&:first)
          sections = [0, *offsets, contents.length].uniq.each_cons(2).map { |start, finish| contents[start...finish] }
          versions = sections.map { |part| part.lines.first[/\A {0,3}##[ \t]+(\d+(?:\.\d+){0,2})[ \t]*\r?\n?\z/, 1] }
        else
          sections = contents.split(/(?=#{VERSION_HEADING})/)
          versions = sections.map { |part| part.lines.first.chomp if part.match?(VERSION_HEADING) }
        end
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

      # Return line offsets and levels of ATX headings, ignoring code fences and HTML comments.
      def self.markdown_headings(contents)
        headings = []
        fence = nil
        html_comment = false
        offset = 0
        contents.each_line do |line|
          if fence
            fence = nil if line.match?(/\A {0,3}#{Regexp.escape(fence[0])}{#{fence.length},}[ \t]*\r?\n?\z/)
          elsif html_comment || line.match?(/\A {0,3}<!--/)
            html_comment = !line.include?('-->')
          elsif (match = line.match(/\A {0,3}(`{3,}(?!.*`)|~{3,})/))
            fence = match[1]
          elsif (match = line.match(/\A {0,3}(\#{1,6})(?:[ \t]+|\r?\n?\z)/))
            headings << [offset, match[1].length]
          end
          offset += line.length
        end
        UI.user_error!('Unterminated code fence in Markdown release notes') if fence
        UI.user_error!('Unterminated HTML comment in Markdown release notes') if html_comment
        headings
      end
      private_class_method :markdown_headings

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
