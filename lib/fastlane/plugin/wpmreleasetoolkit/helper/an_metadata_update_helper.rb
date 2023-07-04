module Fastlane
  module Helper
    # Basic line handler
    class AnMetadataBlock
      attr_reader :block_key

      def initialize(block_key)
        @block_key = block_key
      end

      def handle_line(fw, line)
        fw.puts(line) # Standard line handling: just copy
      end

      def is_handler_for(key)
        true
      end
    end

    class AnUnknownMetadataBlock < AnMetadataBlock
      attr_reader :content_file_path

      def initialize
        super(nil)
      end
    end

    class AnStandardMetadataBlock < AnMetadataBlock
      attr_reader :content_file_path

      def initialize(block_key, content_file_path)
        super(block_key)
        @content_file_path = content_file_path
      end

      def is_handler_for(key)
        key == @block_key.to_s
      end

      def handle_line(fw, line)
        # put the new content on block start
        # and skip all the other content
        generate_block(fw) if line.start_with?('msgctxt')
      end

      def generate_block(fw)
        # init
        fw.puts("msgctxt \"#{@block_key}\"")
        line_count = File.foreach(@content_file_path).inject(0) { |c, _line| c + 1 }

        if line_count <= 1
          # Single line output
          fw.puts("msgid \"#{File.read(@content_file_path).rstrip}\"")
        else
          # Multiple line output
          fw.puts('msgid ""')

          # insert content
          File.open(@content_file_path, 'r').each do |line|
            fw.puts("\"#{line.strip}\\n\"")
          end
        end

        # close
        fw.puts('msgstr ""')
        fw.puts('')
      end
    end

    class AnReleaseNoteMetadataBlock < AnStandardMetadataBlock
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

    class AnReleaseNoteShortMetadataBlock < AnReleaseNoteMetadataBlock
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
