require_relative 'release_note_metadata_block'

module Fastlane
  module Helper
    class ReleaseNoteShortMetadataBlock < ReleaseNoteMetadataBlock
      def initialize(block_key, content_file_path, release_version)
        super
        @rel_note_key = 'release_note_short'
        @release_version = release_version
        generate_keys(release_version)
      end

      def is_handler_for(key)
        values = key.split('_')
        key.start_with?(@rel_note_key) && values.length == 4 && is_int?(values[3].sub(/^0*/, ''))
      end

      def generate_block(file)
        super unless File.empty?(@content_file_path)
      end
    end
  end
end
