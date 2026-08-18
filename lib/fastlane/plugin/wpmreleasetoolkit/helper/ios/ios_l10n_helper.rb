# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'nokogiri'
require 'open3'
require 'open-uri'
require 'tempfile'
require_relative '../glotpress_downloader'

module Fastlane
  module Helper
    module Ios
      class L10nHelper
        # Returns the type of a `.strings` file (XML, binary or ASCII)
        #
        # @param [String] path The path to the `.strings` file to check
        # @param [Boolean] assume_valid Skip the `plutil -lint` validity check when the caller has already
        #        confirmed the file parses (e.g. via `read_strings_file_as_hash`), avoiding a redundant
        #        `plutil` invocation. Only the format detection (`file`) then runs.
        # @return [Symbol] The file format used by the `.strings` file. Can be one of:
        #         - `:text` for the ASCII-plist file format (containing typical `"key" = "value";` lines)
        #         - `:xml` for XML plist file format (can be used if machine-generated, especially since there's no official way/tool to generate the ASCII-plist file format as output)
        #         - `:binary` for binary plist file format (usually only true for `.strings` files converted by Xcode at compile time and included in the final `.app`/`.ipa`)
        #         - `nil` if the file does not exist or is neither of those format (e.g. not a `.strings` file at all)
        #
        def self.strings_file_type(path:, assume_valid: false)
          return :text if File.empty?(path) # If completely empty file, consider it as a valid `.strings` files in textual format

          # Start by checking it seems like a valid property-list file (and not e.g. an image or plain text file).
          # A caller that has already parsed the file can skip this redundant check via `assume_valid: true`.
          unless assume_valid
            _, status = Open3.capture2('/usr/bin/plutil', '-lint', path)
            return nil unless status.success?
          end

          # If it is a valid property-list file, determine the actual format used
          format_desc, status = Open3.capture2('/usr/bin/file', path)
          return nil unless status.success?

          case format_desc
          when /Apple binary property list/ then :binary
          when /XML/ then :xml
          when /text/ then :text
          end
        end

        # Read a file line by line and iterate over it (just like `File.readlines` does),
        # except that it also detects the encoding used by the file (using the BOM if present) when reading it,
        # and then convert each line to UTF-8 before yielding it
        #
        # This is particularly useful if you need to then use a `RegExp` to match part of the lines you're iterating over,
        # as the `RegExp` (which will typically be UTF-8) and the string you're matching with it have to use the same encoding
        # (otherwise we would get a `Encoding::CompatibilityError`)
        #
        # @important If you are then using a `RegExp` to match the UTF-8 lines you iterate on,
        # remember to use the `u` flag on it (`/…/u`) to make it UTF-8-aware too.
        #
        # @param [String] file The path to the file to read
        # @yield each line read from the file, after converting it to the UTF-8 encoding
        #
        def self.read_utf8_lines(file)
          # Be sure to guess file encoding using the Byte-Order-Mark, and fallback to UTF-8 if there's no BOM.
          File.readlines(file, mode: 'rb:BOM|UTF-8').map do |line|
            # Ensure the line is re-encoded to UTF-8 regardless of the encoding that was used in the input file
            line.encode(Encoding::UTF_8)
          end
        end

        # Merge the content of multiple `.strings` files into a new `.strings` text file.
        #
        # @param [Hash<String, String>] paths The paths of the `.strings` files to merge together, associated with the prefix to prepend to each of their respective keys
        # @param [String] output_path The path to the merged `.strings` file to generate as a result.
        # @return [Array<String>] List of duplicate keys found while validating the merge.
        #
        # @note For now, this method only supports merging `.strings` file in `:text` format
        #       and basically concatenates the files (+ checking for duplicates in the process)
        # @note The method is able to handle input files which are using different encodings,
        #       guessing the encoding of each input file using the BOM (and defaulting to UTF8).
        #       The generated file will always be in utf-8, by convention.
        # @note Dictionary- and array-valued entries (`"k" = { … };`, `"k" = ( … );`, nesting allowed) are
        #       prefixed on their outer key with the value preserved verbatim. If a file still holds some
        #       construct the tokenizer can't rewrite, its lines are copied through unprefixed with a warning
        #       (and its keys are then bookkept unprefixed too, so the reported duplicates stay accurate)
        #       rather than aborting the whole merge.
        #
        # @raise [RuntimeError] If one of the paths provided is not in text format (but XML or binary instead), or if any of the files are missing.
        #
        def self.merge_strings(paths:, output_path:)
          duplicates = []
          Tempfile.create('wpmrt-l10n-merge-', encoding: 'utf-8') do |tmp_file|
            all_keys_found = []

            tmp_file.write("/* Generated File. Do not edit. */\n\n")
            paths.each do |input_file, prefix|
              next if File.empty?(input_file) # Skip existing but totally empty files, to avoid adding useless `MARK:` comment for them

              fmt = strings_file_type(path: input_file)
              raise "The file `#{input_file}` does not exist or is of unknown format." if fmt.nil?
              raise "The file `#{input_file}` is in #{fmt} format but we currently only support merging `.strings` files in text format." unless fmt == :text

              raw_keys = read_strings_file_as_hash(path: input_file).keys

              tmp_file.write("/* MARK: - #{File.basename(input_file)} */\n\n")
              # Add the prefix to every key. We tokenize via `StringsFileValidationHelper.prefix_keys` rather than
              # matching keys with a line-based regex, so that keys are found regardless of where `.strings` comments
              # sit (e.g. `CFBundleName /* note */ = WordPress;`) and `key = value`-looking text inside a comment is
              # left alone. It also handles dictionary/array values (`"k" = { … };`) — prefixing the outer key and
              # copying the value verbatim.
              lines = read_utf8_lines(input_file)
              applied_prefix = prefix
              begin
                lines = Fastlane::Helper::Ios::StringsFileValidationHelper.prefix_keys(lines: lines, prefix: prefix)
              rescue StandardError => e
                # `plutil` may still accept a construct the tokenizer can't rewrite: it parses fine (so the file
                # clears the `:text` gate above) yet `prefix_keys` raises on it. Fail soft: copy this file's lines
                # through unprefixed rather than aborting the whole merge — mirroring the scanner path, where
                # `scan_for_duplicate_keys` returns `:unscannable` instead of crashing the lane. `lines` is untouched
                # by the raise (the assignment above never completes), so it still holds the original file contents,
                # and `applied_prefix` records that the keys went out *unprefixed* so the bookkeeping below matches.
                applied_prefix = ''
                UI.important("Could not add prefix `#{prefix}` to the keys in `#{input_file}` (#{e.message}); copying its lines through unprefixed.")
              end

              # Bookkeep the keys as they were actually written — prefixed, or unprefixed on the fail-soft path.
              # Doing this *after* the rewrite keeps the reported duplicates consistent with the merged file even
              # when prefixing fell back, so a genuine collision is still surfaced rather than silently collapsed.
              string_keys = raw_keys.map { |k| "#{applied_prefix}#{k}" }
              duplicates += (string_keys & all_keys_found) # Find duplicates using Array intersection, and add those to duplicates list
              all_keys_found += string_keys

              lines.each { |line| tmp_file.write(line) }
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
          return {} if File.empty?(path) # Return empty hash if completely empty file

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
                translations.sort.each do |k, v| # NOTE: use `sort` just in order to be deterministic over various runs
                  xml.key(k.to_s)
                  xml.string(v.to_s)
                end
              end
            end
          end
          File.write(output_path, builder.to_xml)
        end

        # Downloads the export from GlotPress for a given locale and given filters.
        #
        # @param [String] project_url The URL to the GlotPress project to export from, e.g. `"https://translate.wordpress.org/projects/apps/ios/dev"`
        # @param [String] locale The GlotPress locale code to download strings for.
        # @param [Hash{Symbol=>String}] filters The hash of filters to apply when exporting from GlotPress.
        #                               Typical examples include `{ status: 'current' }` or `{ status: 'review' }`.
        # @param [String, IO] destination The path or `IO`-like instance, where to write the downloaded file on disk.
        # @param [Boolean] fail_on_error Whether to fail on request errors.
        #
        def self.download_glotpress_export_file(project_url:, locale:, filters:, destination:, fail_on_error: false)
          query_params = (filters || {}).transform_keys { |k| "filters[#{k}]" }.merge(format: 'strings')
          url = "#{project_url.chomp('/')}/#{locale}/default/export-translations/?#{URI.encode_www_form(query_params)}"

          Fastlane::Helper::GlotPressDownloader.download(
            url: url,
            locale: locale,
            auto_retry: true,
            fail_on_error: fail_on_error
          ) do |response_body|
            if destination.is_a?(String)
              File.write(destination, response_body)
            else
              destination.write(response_body)
            end
          rescue StandardError => e
            prefix = fail_on_error ? 'Error writing downloaded locale' : 'Error downloading locale'
            message = "#{prefix} `#{locale}` — #{e.message} (#{url})"
            fail_on_error ? UI.user_error!(message) : UI.error(message)
            false
          end
        end
      end
    end
  end
end
