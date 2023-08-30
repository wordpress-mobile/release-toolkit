require_relative 'metadata_block'
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

        version_major -= 1 if version_minor == 0
        version_minor = version_minor == 0 ? 9 : version_minor - 1

        @old_key = "v#{version_major}.#{version_minor}-whats-new"
      end

      def is_handler_for(key)
        key.start_with?('v') && key.end_with?('-whats-new')
      end

      def handle_line(fw, line)
        # put content on block start or if copying the latest one
        # and skip all the other content
        generate_block(fw) if line.start_with?('msgctxt')
      end

      def generate_block(fw)
        # init
        fw.puts("msgctxt \"#{@new_key}\"")
        fw.puts('msgid ""')

        # insert content
        File.open(@content_file_path, 'r').each do |line|
          fw.puts("\"#{line.strip}\\n\"")
        end

        # close
        fw.puts('msgstr ""')
        fw.puts('')
      end
    end

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

        version_major -= 1 if version_minor == 0
        version_minor = version_minor == 0 ? 9 : version_minor - 1

        @keep_key = "#{@rel_note_key}_#{version_major.to_s.rjust(2, '0')}#{version_minor}"
      end

      def is_handler_for(key)
        values = key.split('_')
        key.start_with?(@rel_note_key) && values.length == 3 && is_int?(values[2].sub(/^0*/, ''))
      end

      def handle_line(fw, line)
        # put content on block start or if copying the latest one
        # and skip all the other content
        if line.start_with?('msgctxt')
          key = extract_key(line)
          @is_copying = (key == @keep_key)
          generate_block(fw) if @is_copying
        end

        fw.puts(line) if @is_copying
      end

      def generate_block(fw)
        # init
        fw.puts("msgctxt \"#{@new_key}\"")
        fw.puts('msgid ""')
        fw.puts("\"#{@release_version}:\\n\"")

        # insert content
        File.open(@content_file_path, 'r').each do |line|
          fw.puts("\"#{line.strip}\\n\"")
        end

        # close
        fw.puts('msgstr ""')
        fw.puts('')
      end

      def extract_key(line)
        line.split[1].tr('\"', '')
      end

      def is_int?(value)
        true if Integer(value) rescue false
      end
    end

    class ReleaseNoteShortMetadataBlock < ReleaseNoteMetadataBlock
      def initialize(block_key, content_file_path, release_version)
        super(block_key, content_file_path, release_version)
        @rel_note_key = 'release_note_short'
        @release_version = release_version
        generate_keys(release_version)
      end

      def is_handler_for(key)
        values = key.split('_')
        key.start_with?(@rel_note_key) && values.length == 4 && is_int?(values[3].sub(/^0*/, ''))
      end

      def generate_block(fw)
        super(fw) unless File.empty?(@content_file_path)
      end
    end
  end
end
