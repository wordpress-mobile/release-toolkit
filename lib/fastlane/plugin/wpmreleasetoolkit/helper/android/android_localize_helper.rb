require 'fastlane_core/ui/ui'
require 'fileutils'
require 'nokogiri'
require 'open-uri'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?('UI')

  module Helper
    module Android
      module LocalizeHelper
        LIB_SOURCE_XML_ATTR = 'a8c-src-lib'.freeze

        # Checks if `string_node` has the `content_override` flag set
        def self.skip_string_by_tag?(string_node)
          skip = string_node.attr('content_override') == 'true' unless string_node.attr('content_override').nil?
          if skip
            UI.message " - Skipping #{string_node.attr('name')} string"
            return true
          end

          return false
        end

        # Checks if `string_name` is in the exclusion list
        def self.skip_string_by_exclusion_list?(library, string_name)
          return false if library[:exclusions].nil?

          skip = library[:exclusions].include?(string_name)
          if skip
            UI.message " - Skipping #{string_name} string"
            return true
          end
        end

        # Adds the appropriate XML attributes to an XML `<string>` node according to library configuration
        def self.add_xml_attributes!(string_node, library)
          if library[:add_ignore_attr] == true
            existing_ignores = (string_node['tools:ignore'] || '').split(',')
            existing_ignores.append('UnusedResources') unless existing_ignores.include?('UnusedResources')
            string_node['tools:ignore'] = existing_ignores.join(',')
          end
          string_node[LIB_SOURCE_XML_ATTR] = library[:source_id] unless library[:source_id].nil?
        end

        # Merge a single `lib_string_node` XML node into the `main_strings_xml``
        def self.merge_string_node(main_strings_xml, library, lib_string_node)
          string_name = lib_string_node.attr('name')
          string_content = lib_string_node.content

          # Skip strings in the exclusions list
          return :skipped if skip_string_by_exclusion_list?(library, string_name)

          # Search for the string in the main file
          result = :added
          main_strings_xml.xpath('//string').each do |main_string_node|
            if main_string_node.attr('name') == string_name
              # Skip if the string has the content_override tag
              return :skipped if skip_string_by_tag?(main_string_node)

              # If nodes are equivalent, skip
              return :found if lib_string_node =~ main_string_node

              # The string needs an update
              if main_string_node.attr('tools:ignore').nil?
                # No `tools:ignore` attribute; completely replace existing main string node with lib's one
                add_xml_attributes!(lib_string_node, library)
                main_string_node.replace lib_string_node
              else
                # Has the `tools:ignore` flag; update the content without touching the other existing attributes
                add_xml_attributes!(main_string_node, library)
                main_string_node.content = string_content
              end
              return :updated
            end
          end

          # String not found, or removed because needing update and not in the exclusion list: add to the main file
          add_xml_attributes!(lib_string_node, library)
          main_strings_xml.xpath('//string').last().add_next_sibling("\n#{' ' * 4}#{lib_string_node.to_xml().strip}")
          return result
        end

        # Verify a string node from a library has properly been merged into the main one
        def self.verify_string(main_strings_xml, library, lib_string_node)
          string_name = lib_string_node.attr('name')
          string_content = lib_string_node.content

          # Skip strings in the exclusions list
          return if skip_string_by_exclusion_list?(library, string_name)

          # Search for the string in the main file
          main_strings_xml.xpath('//string').each do |main_string_node|
            if main_string_node.attr('name') == string_name
              # Skip if the string has the content_override tag
              return if skip_string_by_tag?(main_string_node)

              # Check if up-to-date
              UI.user_error!("String #{string_name} [#{string_content}] has been updated in the main file but not in the library #{library[:library]}.") if main_string_node.content != string_content
              return
            end
          end

          # String not found and not in the exclusion list
          UI.user_error!("String #{string_name} [#{string_content}] was found in library #{library[:library]} but not in the main file.")
        end

        # Merge strings from a library into the strings.xml of the main app
        #
        # @param [String] main Path to the main strings.xml file (something like `…/res/values/strings.xml`)
        # @param [Hash] library Hash describing the library to merge. The Hash should contain the following keys:
        #                       - `:library`: The human readable name of the library, used to display in console messages
        #                       - `:strings_path`: The path to the strings.xml file of the library to merge into the main one
        #                       - `:exclusions`: An array of strings keys to exclude during merge. Any of those keys from the
        #                         library's `strings.xml` will be skipped and won't be merged into the main one.
        #                       - `:source_id`: An optional `String` which will be added as the `a8c-src-lib` XML attribute
        #                         to strings coming from this library, to help identify their source in the merged file.
        #                       - `:add_ignore_attr`: If set to `true`, will add `tools:ignore="UnusedResources"` to merged strings.
        #
        # @return [Boolean] True if at least one string from the library has been added to (or has updated) the main strings file.
        #
        def self.merge_lib(main, library)
          UI.message("Merging #{library[:library]} strings into #{main}")
          main_strings_xml = File.open(main) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
          lib_strings_xml = File.open(library[:strings_path]) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }

          updated_count = 0
          untouched_count = 0
          added_count = 0
          skipped_count = 0
          lib_strings_xml.xpath('//string').each do |string_node|
            res = merge_string_node(main_strings_xml, library, string_node)
            case res
            when :updated
              UI.verbose "#{string_node.attr('name')} updated."
              updated_count = updated_count + 1
            when :found
              untouched_count = untouched_count + 1
            when :added
              UI.verbose "#{string_node.attr('name')} added."
              added_count = added_count + 1
            when :skipped
              skipped_count = skipped_count + 1
            else
              UI.user_error!("Internal Error! #{res}")
            end
          end

          File.open(main, 'w:UTF-8') do |f|
            f.write(main_strings_xml.to_xml(indent: 4))
          end

          UI.message("Done (#{added_count} added, #{updated_count} updated, #{untouched_count} untouched, #{skipped_count} skipped).")
          return (added_count + updated_count) != 0
        end

        def self.verify_diff(diff_string, main_strings, lib_strings, library)
          if diff_string.start_with?('name=')
            diff_string.slice!('name="')

            end_index = diff_string.index('"')
            end_index ||= diff_string.length # Use the whole string if there's no '"'

            diff_string = diff_string.slice(0..(end_index - 1))

            lib_strings.xpath('//string').each do |string_node|
              res = verify_string(main_strings, library, string_node) if string_node.attr('name') == diff_string
            end
          end
        end

        def self.verify_lib(main, library, source_diff)
          UI.message("Checking #{library[:library]} strings vs #{main}")
          main_strings = File.open(main) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
          lib_strings = File.open(library[:strings_path]) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }

          verify_local_diff(main, library, main_strings, lib_strings)
          verify_pr_diff(main, library, main_strings, lib_strings, source_diff) unless source_diff.nil?
        end

        def self.verify_local_diff(main, library, main_strings, lib_strings)
          `git diff #{main}`.each_line do |line|
            if line.start_with?('+ ') || line.start_with?('- ')
              diffs = line.gsub(/\s+/m, ' ').strip.split
              diffs.each do |diff|
                verify_diff(diff, main_strings, lib_strings, library)
              end
            end
          end
        end

        def self.verify_pr_diff(main, library, main_strings, lib_strings, source_diff)
          source_diff.each_line do |line|
            if line.start_with?('+ ') || line.start_with?('- ')
              diffs = line.gsub(/\s+/m, ' ').strip.split
              diffs.each do |diff|
                verify_diff(diff, main_strings, lib_strings, library)
              end
            end
          end
        end

        ########
        # @!group Downloading translations from GlotPress
        ########

        # Create the `available_languages.xml` file.
        #
        # @param [String] res_dir The relative path to the `…/src/main/res` directory
        # @param [Array<String>] locale_codes The list of locale codes to include in the available_languages.xml file
        #
        def self.create_available_languages_file(res_dir:, locale_codes:)
          doc = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            xml.comment('Warning: Auto-generated file, do not edit.')
            xml.resources do
              xml.send(:'string-array', name: 'available_languages', translatable: 'false') do
                locale_codes.each { |code| xml.item(code.gsub('-r', '_')) }
              end
            end
          end
          File.write(File.join(res_dir, 'values', 'available_languages.xml'), doc.to_xml)
        end

        # Download translations from GlotPress
        #
        # @param [String] res_dir The relative path to the `…/src/main/res` directory.
        # @param [String] glotpress_project_url The base URL to the glotpress project to download the strings from.
        # @param [Hash{String=>String}, Array] glotpress_filters
        #        The filters to apply when exporting strings from GlotPress.
        #        Typical examples include `{ status: 'current' }` or `{ status: 'review' }`.
        #        If an array of Hashes is provided instead of a single Hash, this method will perform as many
        #        export requests as items in this array, then merge all the results – useful for OR-ing multiple filters.
        # @param [Array<Hash{Symbol=>String}>] locales_map
        #        An array of locales to download. Each item in the array must be a Hash
        #        with keys `:glotpress` and `:android` containing the respective locale codes.
        #
        def self.download_from_glotpress(res_dir:, glotpress_project_url:, glotpress_filters: { status: 'current' }, locales_map:)
          glotpress_filters = [glotpress_filters] unless glotpress_filters.is_a?(Array)

          attributes_to_copy = %w[formatted] # Attributes that we want to replicate into translated `string.xml` files
          orig_file = File.join(res_dir, 'values', 'strings.xml')
          orig_xml = File.open(orig_file) { |f| Nokogiri::XML(f, nil, Encoding::UTF_8.to_s) }
          orig_attributes = orig_xml.xpath('//string').map { |tag| [tag['name'], tag.attributes.select { |k, _| attributes_to_copy.include?(k) }] }.to_h

          locales_map.each do |lang_codes|
            all_xml_documents = glotpress_filters.map do |filters|
              UI.message "Downloading translations for '#{lang_codes[:android]}' from GlotPress (#{lang_codes[:glotpress]}) [#{filters}]..."
              download_glotpress_export_file(project_url: glotpress_project_url, locale: lang_codes[:glotpress], filters: filters)
            end.compact
            next if all_xml_documents.empty?

            # Merge all XMLs together
            merged_xml = merge_xml_documents(all_xml_documents)

            # Process XML (text substitutions, replicate attributes, quick-lint string)
            merged_xml.xpath('//string').each do |string_tag|
              apply_substitutions(string_tag)
              orig_attributes[string_tag['name']]&.each { |k, v| string_tag[k] = v }
              quick_lint(string_tag, lang_codes[:android])
            end
            merged_xml.xpath('//string-array/item').each { |item_tag| apply_substitutions(item_tag) }

            # Save
            lang_dir = File.join(res_dir, "values-#{lang_codes[:android]}")
            FileUtils.mkdir(lang_dir) unless Dir.exist?(lang_dir)
            lang_file = File.join(lang_dir, 'strings.xml')
            File.open(lang_file, 'w') { |f| merged_xml.write_to(f, encoding: Encoding::UTF_8.to_s, indent: 4) }
          end
        end

        #####################
        # Private Helpers
        #####################

        # Downloads the export from GlotPress for a given locale and given filters
        #
        # @param [String] project_url The URL to the GlotPress project to export from.
        # @param [String] locale The GlotPress locale code to download strings for.
        # @param [Hash{Symbol=>String}] filters The hash of filters to apply when exporting from GlotPress.
        #                               Typical examples include `{ status: 'current' }` or `{ status: 'review' }`.
        # @return [Nokogiri::XML] the download XML document, parsed as a Nokogiri::XML object
        #
        def self.download_glotpress_export_file(project_url:, locale:, filters:)
          query_params = filters.transform_keys { |k| "filters[#{k}]" }.merge(format: 'android')
          uri = URI.parse("#{project_url.chomp('/')}/#{locale}/default/export-translations/?#{URI.encode_www_form(query_params)}")
          begin
            uri.open { |f| Nokogiri::XML(f.read.gsub("\t", '    '), nil, Encoding::UTF_8.to_s) }
          rescue StandardError => e
            UI.error "Error downloading #{locale} - #{e.message}"
            return nil
          end
        end
        private_class_method :download_glotpress_export_file

        # Merge multiple Nokogiri::XML `strings.xml` documents together
        #
        # @param [Array<Nokogiri::XML::Document>] all_xmls Array of the Nokogiri XML documents to merge together
        # @return [Nokogiri::XML::Document] The merged document.
        #
        # @note The first document in the array is used as starting point. Then string/resources from other docs are merged into it.
        #       If a string/resource with a given `name` is present in multiple documents, the node of the last one wins.
        #
        def self.merge_xml_documents(all_xmls)
          return all_xmls.first if all_xmls.count <= 1

          merged_xml = all_xmls.first.dup # Use the first XML as starting point
          resources_node = merged_xml.xpath('/resources').first
          # For each other XML, find all the nodes with a name attribute, and merge them in
          all_xmls.drop(1).each do |other_xml|
            other_xml.xpath('/resources/*[@name]').each do |other_node|
              existing_node = merged_xml.xpath("//#{other_node.name}[@name='#{other_node['name']}']").first
              if existing_node.nil?
                resources_node << '    ' << other_node << "\n"
              else
                existing_node.replace(other_node)
              end
            end
          end
          merged_xml
        end
        private_class_method :merge_xml_documents

        # Apply some common text substitutions to tag contents
        #
        # @param [Nokogiri::XML::Node] tag The XML tag/node to apply substitutions to
        #
        def self.apply_substitutions(tag)
          tag.content = tag.content.gsub('...', '…')

          # Typography en-dash
          if tag.content.include?('-')
            tag.content = tag.content.gsub(/(\d+\s*)-(\s*\d+)/) do |str|
              match = Regexp.last_match # of type `MatchData`. match[0] == str == whole match, match[1] = 1st capture group (left part of the range), match[2] = second capture group (right part of the range)
              is_negative_number = match[2][0] != ' ' && match[1][-1] == ' ' # if right part of range does not start with a space (e.g. `-3`), but left part of range does end with space, it's not a range after all but more likely a list containing negative numbers in it (e.g. `2 -3`)
              is_negative_number ? str : "#{match[1]}\u{2013}#{match[2]}"
            end
          end
        end
        private_class_method :apply_substitutions

        # Perform some quick basic checks about an individual `<string>` tag and print warnings accordingly
        #
        # @param [Nokogiri::XML::Node] string_tag The XML tag/node to check
        # @param [String] lang The language we are currently processing. Used for providing context during logging / warning message
        #
        def self.quick_lint(string_tag, lang)
          if string_tag['formatted'] == 'false' && string_tag.content.include?('%%')
            UI.important "Warning: [#{lang}] translation for '#{string_tag['name']}' has attribute formatted=false, but still contains escaped '%%' in translation."
          end
        end
        private_class_method :quick_lint

        # @!endgroup
      end
    end
  end
end

# Source: https://stackoverflow.com/questions/7825258/determine-if-two-nokogiri-nodes-are-equivalent?rq=1
# There may be better solutions now that Ruby supports canonicalization.
module Nokogiri
  module XML
    class Node
      # Return true if this node is content-equivalent to other, false otherwise
      def =~(other)
        return true if self == other
        return false unless name == other.name

        stype = node_type
        otype = other.node_type
        return false unless stype == otype

        sa = attributes
        oa = other.attributes
        return false unless sa.length == oa.length

        sa = sa.sort.map { |n, a| [n, a.value, a.namespace && a.namespace.href] }
        oa = oa.sort.map { |n, a| [n, a.value, a.namespace && a.namespace.href] }
        return false unless sa == oa

        skids = children
        okids = other.children
        return false unless skids.length == okids.length
        return false if stype == TEXT_NODE && (content != other.content)

        sns = namespace
        ons = other.namespace
        return false if !sns ^ !ons
        return false if sns && (sns.href != ons.href)

        skids.to_enum.with_index.all? { |ski, i| ski =~ okids[i] }
      end
    end
  end
end
