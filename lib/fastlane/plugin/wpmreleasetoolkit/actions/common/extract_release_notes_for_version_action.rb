require 'fastlane/action'

module Fastlane
  module Actions
    class ExtractReleaseNotesForVersionAction < Action
      def self.run(params)
        version = params[:version]
        release_notes_file_path = params[:release_notes_file_path]
        extracted_notes_file_path = params[:extracted_notes_file_path]

        extracted_notes_file = File.open(extracted_notes_file_path, 'w') unless extracted_notes_file_path.blank?

        extract_notes(release_notes_file_path, version) do | line |
          extracted_notes_file.nil? ? puts(line) : extracted_notes_file.write(line)
        end

        unless extracted_notes_file.nil?
          extracted_notes_file.close()
          check_and_commit_extracted_notes_file(extracted_notes_file_path, version)
        end
      end

      def self.extract_notes(release_notes_file_path, version)
        state = :discarding
        File.open(release_notes_file_path).each do | line |
          case state
          when :discarding
            if (line.match(/^(\d+\.)?(\d+\.)?(\*|\d+)$/)) and (line.strip() == version)
              state = :evaluating
            end
          when :evaluating
            state = (line.match(/-/)) ? :extracting : :discarding
          when :extracting
            if (line.match(/^(\d+\.)?(\d+\.)?(\*|\d+)$/))
              state = :discarding
              return
            else
             yield(line)
            end
          end
        end
      end

      def self.check_and_commit_extracted_notes_file(file_path, version)
        Action.sh("git add #{file_path}")
        Action.sh("git diff-index --quiet HEAD || git commit -m \"Update draft release notes for #{version}.\"")
      end

      def self.description
        "Extract the release notes for a specific version"
      end

      def self.authors
        ["Lorenzo Mattei"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Creates a release and uploads the provided assets"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :version,
                                        env_name: "GHHELPER_EXTRACT_NOTES_VERSION",
                                        description: "The version of the release",
                                        optional: false,
                                        is_string: true),
          FastlaneCore::ConfigItem.new(key: :release_notes_file_path,
                                        env_name: "GHHELPER_EXTRACT_NOTES_FILE_PATH",
                                        description: "The path to the file that contains the release notes",
                                        optional: false,
                                        is_string: true),
          FastlaneCore::ConfigItem.new(key: :extracted_notes_file_path,
                                          env_name: "GHHELPER_EXTRACT_NOTES_EXTRACTED_FILE_PATH",
                                          description: "The path to the file that will contain the extracted release notes",
                                          optional: true,
                                          is_string: true),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
