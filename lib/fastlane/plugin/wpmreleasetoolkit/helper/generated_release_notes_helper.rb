# frozen_string_literal: true

module Fastlane
  module Helper
    module GeneratedReleaseNotesHelper
      VERSION_HEADING = /^(\d+(?:\.\d+){0,2})\r?\n[-=]+\r?\n/

      # Convert GitHub's generated Markdown into the format consumed by release automation.
      # @param [String] version The numeric release version.
      # @param [String] markdown Output from get_prs_between_tags.
      # @return [String] The complete version section.
      def self.section(version:, markdown:)
        UI.user_error!('Expected a numeric release version') unless version.match?(/\A\d+(?:\.\d+){0,2}\z/)
        markdown = markdown.sub(/\A<!-- Release notes generated using configuration in [^\n]* -->\s*/, '')
        empty_changelog = markdown.strip.match?(%r{\A\*\*Full Changelog\*\*: https://github\.com/[^/\s]+/[^/\s]+/compare/\S+\z})
        UI.user_error!('Unrecognized generated release notes') unless empty_changelog || markdown.start_with?('## New PRs since ', "## What's Changed")

        # Contributors can also contain PR links; they are not release note entries.
        changes = markdown.split(/^## (?:New Contributors|Contributors)\s*$/, 2).first
        entries = changes.lines.filter_map do |line|
          next unless line.match?(/^[-*] /)

          match = line.strip.match(%r{\A[-*] (.+) by @\S+ in (https://github\.com/[^/\s]+/[^/\s]+/pull/\d+)\z})
          UI.user_error!("Unrecognized generated PR entry: #{line.strip}") unless match
          title, url = match.captures
          priority = title.match?(/\A\[\*+\]/) ? '' : '[*] '
          "- #{priority}#{title} [#{url}]"
        end

        "#{version}\n-----\n#{entries.join("\n")}\n\n"
      end

      # Replace one version while preserving all other sections byte for byte.
      # @param [String] contents Existing RELEASE-NOTES.txt contents.
      # @param [String] version The section to replace or insert.
      # @param [String] section The generated version section.
      # @return [String] Updated file contents.
      def self.update(contents:, version:, section:)
        headings = contents.to_enum(:scan, VERSION_HEADING).map { Regexp.last_match }
        UI.user_error!('No version headings found in the release notes file') if headings.empty?
        matches = headings.select { |heading| heading[1] == version }
        UI.user_error!("Duplicate release notes sections for #{version}") if matches.length > 1

        heading = matches.first
        start = heading ? heading.begin(0) : headings.first.begin(0)
        finish = heading ? (headings[headings.index(heading) + 1]&.begin(0) || contents.length) : start
        newline = contents.include?("\r\n") ? "\r\n" : "\n"
        contents[0...start] + section.gsub("\n", newline) + contents[finish..]
      end
    end
  end
end
