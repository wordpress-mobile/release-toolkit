require_relative 'metadata_block'

module Fastlane
  module Helper
    class UnknownMetadataBlock < MetadataBlock
      attr_reader :content_file_path

      def initialize
        super(nil)
      end
    end
  end
end
