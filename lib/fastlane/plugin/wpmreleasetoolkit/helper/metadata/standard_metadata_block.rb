require_relative 'metadata_block'

module Fastlane
  module Helper
    class StandardMetadataBlock < MetadataBlock
      attr_reader :content_file_path

      def initialize(block_key, content_file_path)
        super(block_key)
        @content_file_path = content_file_path
      end

      def is_handler_for(key)
        key == @block_key.to_s
      end

      def handle_line(file, line)
        # put the new content on block start
        # and skip all the other content
        generate_block(file) if line.start_with?('msgctxt')
      end

      def generate_block(file)
        # init
        file.puts("msgctxt \"#{@block_key}\"")
        line_count = File.foreach(@content_file_path).inject(0) { |c, _line| c + 1 }

        if line_count <= 1
          # Single line output
          file.puts("msgid \"#{File.read(@content_file_path).rstrip}\"")
        else
          # Multiple line output
          file.puts('msgid ""')

          # insert content
          File.open(@content_file_path, 'r').each do |line|
            file.puts("\"#{line.strip}\\n\"")
          end
        end

        # close
        file.puts('msgstr ""')
        file.puts('')
      end
    end
  end
end
