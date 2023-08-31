require_relative 'standard_metadata_block'

module Fastlane
  module Helper
    class WhatsNewMetadataBlock < StandardMetadataBlock
      attr_reader :new_key, :old_key, :rel_note_key, :release_version

      def initialize(block_key, content_file_path, release_version)
        super(block_key, content_file_path)
        @rel_note_key = 'whats_new'
        @release_version = release_version
        generate_keys(release_version)
      end

      def generate_keys(release_version)
        values = release_version.split('.')
        version_major = Integer(values[0])
        version_minor = Integer(values[1])
        @new_key = "v#{release_version}-whats-new"

        version_major -= 1 if version_minor.zero?
        version_minor = version_minor.zero? ? 9 : version_minor - 1

        @old_key = "v#{version_major}.#{version_minor}-whats-new"
      end

      def is_handler_for(key)
        key.start_with?('v') && key.end_with?('-whats-new')
      end

      def handle_line(file, line)
        # put content on block start or if copying the latest one
        # and skip all the other content
        generate_block(file) if line.start_with?('msgctxt')
      end

      def generate_block(file)
        # init
        file.puts("msgctxt \"#{@new_key}\"")
        file.puts('msgid ""')

        # insert content
        File.open(@content_file_path, 'r').each do |line|
          file.puts("\"#{line.strip}\\n\"")
        end

        # close
        file.puts('msgstr ""')
        file.puts('')
      end
    end
  end
end
