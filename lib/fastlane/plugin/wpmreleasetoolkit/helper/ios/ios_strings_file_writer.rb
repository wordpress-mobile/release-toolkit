require 'fastlane_core/ui/ui'
require 'fileutils'

module Fastlane
  module Helper
    module Ios
      module StringsFileWriter
        # @param [String] dir path to destination directory
        # @param [Locale] locale the locale to write the file for
        # @param [File, IO] io The File IO containing the translations downloaded from GlotPress
        def self.write_app_translations_file(dir:, locale:, io:)
          # `dir` is typically `WordPress/Resources/` here
          return unless Locale.valid?(locale, :ios)

          dest = File.join(dir, locale.ios_path)
          FileUtils.mkdir_p(File.dirname(dest))
          UI.message("Writing: #{dest}")
          IO.copy_stream(io, dest)
        end
      end
    end
  end
end

