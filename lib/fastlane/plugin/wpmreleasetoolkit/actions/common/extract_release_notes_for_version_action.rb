require 'fastlane/action'

module Fastlane
  module Actions
    class ExtractReleaseNotesForVersionAction < Action
      def self.run(params)
        version = params[:version]
        release_notes_file_path = params[:release_notes_file_path]
        extracted_notes_file_path = params[:extracted_notes_file_path]

        extracted_notes = ''
        extract_notes(release_notes_file_path, version) do |line|
          extracted_notes += line
        end
        extracted_notes.chomp!('') # Remove any extra empty line(s) at the end

        unless extracted_notes_file_path.nil? || extracted_notes_file_path.empty?
          File.write(extracted_notes_file_path, extracted_notes)
          commit_extracted_notes_file(extracted_notes_file_path, version)
        end

        extracted_notes
      end

      def self.extract_notes(release_notes_file_path, version)
        state = :discarding
        File.open(release_notes_file_path).each do |line|
          case state
          when :discarding
            state = :evaluating if line.match(/^(\d+\.)?(\d+\.)?(\*|\d+)$/) && (line.strip == version)
          when :evaluating
            state = line.match(/-/) ? :extracting : :discarding
          when :extracting
            if line.match(/^(\d+\.)?(\d+\.)?(\*|\d+)$/)
              state = :discarding
              return
            else
              yield(line)
            end
          end
        end
      end

      def self.commit_extracted_notes_file(file_path, version)
        other_action.git_add(path: file_path)
        other_action.git_commit(
          path: file_path,
          message: "Update draft release notes for #{version}",
          allow_nothing_to_commit: true
        )
      end

      def self.description
        'Extract the release notes for a specific version'
      end

      def self.authors
        ['Automattic']
      end

      def self.return_value
        'The content of the extracted release notes (the same text as what was written in the `extracted_notes_file_path` if one was provided)'
      end

      def self.details
        # Optional:
        'Given a file containing release notes and a version, extracts the notes for that version into a dedicated file.'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: 'GHHELPER_EXTRACT_NOTES_VERSION',
                                       description: 'The version of the release',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :release_notes_file_path,
                                       env_name: 'GHHELPER_EXTRACT_NOTES_FILE_PATH',
                                       description: 'The path to the file that contains the release notes',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :extracted_notes_file_path,
                                       env_name: 'GHHELPER_EXTRACT_NOTES_EXTRACTED_FILE_PATH',
                                       description: 'The path to the file that will contain the extracted release notes',
                                       optional: true,
                                       type: String),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
