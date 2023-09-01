require_relative 'metadata_block'
require_relative 'standard_metadata_block'

module Fastlane
  module Helper
    class ReleaseNoteMetadataBlock < StandardMetadataBlock
      attr_reader :new_key, :keep_key, :rel_note_key, :release_version

      def initialize(block_key, content_file_path, release_version)
        super(block_key, content_file_path)
        @rel_note_key = 'release_note'
        @release_version = release_version
        generate_keys(release_version)
      end

      def generate_keys(release_version)
        values = release_version.split('.')
        version_major = Integer(values[0])
        version_minor = Integer(values[1])
        @new_key = "#{@rel_note_key}_#{version_major.to_s.rjust(2, '0')}#{version_minor}"

        version_major -= 1 if version_minor.zero?
        version_minor = version_minor.zero? ? 9 : version_minor - 1

        @keep_key = "#{@rel_note_key}_#{version_major.to_s.rjust(2, '0')}#{version_minor}"
      end

      def is_handler_for(key)
        values = key.split('_')
        key.start_with?(@rel_note_key) && values.length == 3 && is_int?(values[2].sub(/^0*/, ''))
      end

      def handle_line(file, line)
        # put content on block start or if copying the latest one
        # and skip all the other content
        if line.start_with?('msgctxt')
          key = extract_key(line)
          @is_copying = (key == @keep_key)
          generate_block(file) if @is_copying
        end

        file.puts(line) if @is_copying
      end

      def generate_block(file)
        # init
        file.puts("msgctxt \"#{@new_key}\"")
        file.puts('msgid ""')
        file.puts("\"#{@release_version}:\\n\"")

        # insert content
        File.open(@content_file_path, 'r').each do |line|
          file.puts("\"#{line.strip}\\n\"")
        end

        # close
        file.puts('msgstr ""')
        file.puts('')
      end

      def extract_key(line)
        line.split[1].tr('\"', '')
      end

      def is_int?(value)
        true if Integer(value)
      rescue StandardError
        false
      end
    end
  end
end
