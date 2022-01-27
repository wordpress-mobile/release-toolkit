require 'open3'
require 'tempfile'
require 'fileutils'
require 'nokogiri'
require 'json'

module Fastlane
  module Helper
    module Ios
      class L10nHelper
        # Returns the type of a `.strings` file (XML, binary or ASCII)
        #
        # @param [String] path The path to the `.strings` file to check
        # @return [Symbol] The file format used by the `.strings` file. Can be one of:
        #         - `:text` for the ASCII-plist file format (containing typical `"key" = "value";` lines)
        #         - `:xml` for XML plist file format (can be used if machine-generated, especially since there's no official way/tool to generate the ASCII-plist file format as output)
        #         - `:binary` for binary plist file format (usually only true for `.strings` files converted by Xcode at compile time and included in the final `.app`/`.ipa`)
        #         - `nil` if the file does not exist or is neither of those format (e.g. not a `.strings` file at all)
        #
        def self.strings_file_type(path:)
          # Start by checking it seems like a valid property-list file (and not e.g. an image or plain text file)
          _, status = Open3.capture2('/usr/bin/plutil', '-lint', path)
          return nil unless status.success?

          # If it is a valid property-list file, determine the actual format used
          format_desc, status = Open3.capture2('/usr/bin/file', path)
          return nil unless status.success?

          case format_desc
          when /Apple binary property list/ then return :binary
          when /XML/ then return :xml
          when /text/ then return :text
          end
        end

        # Merge the content of multiple `.strings` files into a new `.strings` text file.
        #
        # @param [Array<String>] paths The paths of the `.strings` files to merge together
        # @param [String] into The path to the merged `.strings` file to generate as a result.
        # @return [Array<String>] List of duplicate keys found while validating the merge.
        #
        # @note For now, this method only supports merging `.strings` file in `:text` format
        #       and basically concatenates the files (+ checking for duplicates in the process)
        # @note The method is able to handle input files which are using different encodings,
        #       guessing the encoding of each input file using the BOM (and defaulting to UTF8).
        #       The generated file will always be in utf-8, by convention.
        #
        # @raise [RuntimeError] If one of the paths provided is not in text format (but XML or binary instead), or if any of the files are missing.
        #
        def self.merge_strings(paths:, output_path: nil)
          duplicates = []
          Tempfile.create('wpmrt-l10n-merge-', encoding: 'utf-8') do |tmp_file|
            all_keys_found = []

            tmp_file.write("/* Generated File. Do not edit. */\n\n")
            paths.each do |input_file|
              fmt = strings_file_type(path: input_file)
              raise "The file `#{input_file}` does not exist or is of unknown format." if fmt.nil?
              raise "The file `#{input_file}` is in #{fmt} format but we currently only support merging `.strings` files in text format." unless fmt == :text

              string_keys = read_strings_file_as_hash(path: input_file).keys
              duplicates += (string_keys & all_keys_found) # Find duplicates using Array intersection, and add those to duplicates list
              all_keys_found += string_keys

              tmp_file.write("/* MARK: - #{File.basename(input_file)} */\n\n")
              # Read line-by-line to reduce memory footprint during content copy; Be sure to guess file encoding using the Byte-Order-Mark.
              File.readlines(input_file, mode: 'rb:BOM|UTF-8').each { |line| tmp_file.write(line) }
              tmp_file.write("\n")
            end
            tmp_file.close # ensure we flush the content to disk
            FileUtils.cp(tmp_file.path, output_path)
          end
          duplicates
        end

        # Return the list of translations in a `.strings` file.
        #
        # @param [String] path The path to the `.strings` file to read
        # @return [Hash<String,String>] A dictionary of key=>translation translations.
        # @raise [RuntimeError] If the file is not a valid strings file or there was an error in parsing its content.
        #
        def self.read_strings_file_as_hash(path:)
          output, status = Open3.capture2e('/usr/bin/plutil', '-convert', 'json', '-o', '-', path)
          raise output unless status.success?

          JSON.parse(output)
        end

        # Generate a `.strings` file from a dictionary of string translations.
        #
        # Especially useful to generate `.strings` files not from code, but from keys extracted from another source
        # (like a JSON file export from GlotPress, or subset of keys extracted from the main `Localizable.strings` to generate an `InfoPlist.strings`)
        #
        # @note The generated file will be in XML-plist format
        #       since ASCII plist is deprecated as an output format by every Apple tool so there's no **safe** way to generate ASCII format.
        #
        # @param [Hash<String,String>] translations The dictionary of key=>translation translations to put in the generated `.strings` file
        # @param [String] output_path The path to the `.strings` file to generate
        #
        def self.generate_strings_file_from_hash(translations:, output_path:)
          builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            xml.doc.create_internal_subset(
              'plist',
              '-//Apple//DTD PLIST 1.0//EN',
              'http://www.apple.com/DTDs/PropertyList-1.0.dtd'
            )
            xml.comment('Warning: Auto-generated file, do not edit.')
            xml.plist(version: '1.0') do
              xml.dict do
                translations.each do |k, v|
                  xml.key(k.to_s)
                  xml.string(v.to_s)
                end
              end
            end
          end
          File.write(output_path, builder.to_xml)
        end
      end
    end
  end
end
