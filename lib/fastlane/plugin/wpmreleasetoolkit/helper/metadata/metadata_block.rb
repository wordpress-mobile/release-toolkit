module Fastlane
  module Helper
    # Basic line handler
    class MetadataBlock
      attr_reader :block_key

      def initialize(block_key)
        @block_key = block_key
      end

      def handle_line(file, line)
        file.puts(line) # Standard line handling: just copy
      end

      def is_handler_for(key)
        true
      end
    end
  end
end
