require 'fastlane_core/ui/ui'
require 'fileutils'

module Fastlane
  module Helper
    module Android
      module StringsFileWriter
        # @param [String] dir path to destination directory
        # @param [Locale] locale the locale to write the file for
        # @param [File, IO] io The File IO containing the translations downloaded from GlotPress
        def self.write_app_translations_file(dir:, locale:, io:)
          # `dir` is typically `src/main/res/` here
          return unless Locale.valid?(locale, :android)

          dest = File.join(dir, locale.android_path)
          FileUtils.mkdir_p(File.dirname(dest))

          # TODO: reorder XML nodes alphabetically, for easier diffs
          #   xml = Nokogiri::XML(io, nil, Encoding::UTF_8.to_s)
          #   # … reorder nodes …
          #   File.open(main, 'w:UTF-8') { |f| f.write(xml.to_xml(indent: 4)) }
          # FIXME: For now, just copy blindly until we get time to implement node reordering
          UI.message("Writing: #{dest}")
          IO.copy_stream(io, dest)
        end
      end
    end
  end
end
