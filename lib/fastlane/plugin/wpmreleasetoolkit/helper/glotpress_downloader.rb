require 'fastlane_core/ui/ui'
require 'json'
require 'open-uri'
require 'zip'

module Fastlane
  module Helper
    class GPDownloader
      REQUEST_HEADERS = { 'User-Agent' => Wpmreleasetoolkit::USER_AGENT }

      module FORMAT
        ANDROID = 'android'
        IOS = 'strings'
        JSON = 'json'
      end

      # The host of the GlotPress instance. e.g. `'translate.wordpress.org'`
      attr_accessor :host
      # The path of the project in GlotPress. e.g. `'apps/ios/release-notes'`
      attr_accessor :project

      def initialize(host:, project:)
        @host = host
        @project = project
      end

      # @param [String] gp_locale
      # @param [String] format Typically `'android'`, `'strings'` or `'json'`
      # @param [Hash<String,String>] filters
      #
      # @yield [IO] the corresponding downloaded IO content
      #
      # @note For this case, `project_url` is on the form 'https://translate.wordpress.org/projects/apps/ios/release-notes'
      def download_locale(gp_locale:, format:, filters: { status: 'current'})
        query_params = filters.transform_keys { |k| "filters[#{k}]" }.merge(format: format)
        uri = URI::HTTPS.build(host: host, path: File.join('/', 'projects', project, gp_locale, 'default', 'export-translations'), query: URI.encode_www_form(query_params))

        UI.message "Downloading #{uri}"
        io = begin
          uri.open(REQUEST_HEADERS)
        rescue StandardError => e
          UI.error "Error downloading #{gp_locale} - #{e.message}"
          return
        end
        UI.message "Download done."
        yield io
      end

      # @param [String] format Typically `'android'`, `'strings'` or `'json'`
      # @param [Hash<String,String>] filters
      #
      # @yield For each locale, a tuple of [String], [IO] corresponding to the glotpress locale code and IO content
      #
      # @note requires the GlotPress instance to have the Bulk Downloader plugin installed
      # @note For this case, `project_url` is on the form 'https://translate.wordpress.org/exporter/apps/android/dev/'
      def download_all_locales(format:, filters: { status: 'current'})
        query_params = filters.transform_keys { |k| "filters[#{k}]" }.merge('export-format': format)
        uri = URI::HTTPS.build(host: host, path: File.join('/', 'exporter', project, '-do'), query: URI.encode_www_form(query_params))
        UI.message "Downloading #{uri}"
        zip_stream = uri.open(REQUEST_HEADERS)
        UI.message "Download done."

        Zip::File.open_buffer(zip_stream) do |zip_file|
          zip_file.each do |entry|
            next if entry.name.end_with?('/') && entry.size.zero?

            prefix = File.dirname(entry.name).gsub(/[0-9-]*$/, '') + '-'
            locale = File.basename(entry.name, File.extname(entry.name)).delete_prefix(prefix)
            UI.message "- Found locale in ZIP: #{locale}"

            yield locale, entry.get_input_stream
          end
        end
      end

      # Process a JSON export downloaded from GlotPress, extract keys and translations from it based on the passed `MetadataRules`, and yield each found entry to the caller
      #
      # @param [#read] io
      # @param [Array<MetadataRule>] rules List of rules for each key
      # @param [Block] rule_for_unknown_key An optional block called when a key that does not match any of the rules is encountered.
      #        The block will receive a [String] (key) and must return a `MetadataRule` instance (or nil)
      #
      # @yield [String, MetadataRule, String] yield each (key,matching_rule,value) tuple found in the JSON, after resolving alternates for values exceeding max length
      #
      def self.process_json_export(io:, rules:, rule_for_unknown_key:)
        json = JSON.parse(io.read)
        json.each do |composite_key, values|
          key = composite_key.split(/\u0004/).first # composite_key is a concatenation of key + \u0004 + source
          next if key.nil? || key.end_with?('_short') # skip if alternate key
          value = values.first # Each value in the JSON Hash is an Array of all the translations; but if we provided the right filter, the first one should always be the right one

          rule = rules.find { |r| r.key == key }
          rule = rule_for_unknown_key.call(key) if rule.nil? && !rule_for_unknown_key.nil?
          next if rule.nil?

          if rule.max_len != nil && value.length > rule.max_len
            UI.warning "Translation for #{key} is too long (#{value.length}), trying shorter alternate #{key}."
            short_key = "#{key}_short"
            value = json[short_key]&.first
            if value.nil?
              UI.warning "No shorter alternate (#{short_key}) available, skipping entirely."
              yield key, rule, nil
              next
            end
            if value.length > rule.max_len
              UI.warning "Translation alternate for #{short_key} was too long too (#{value.length}), skipping entirely."
              yield short_key, rule, nil
              next
            end
          end
          yield key, rule, value
        end
      end
    end # class
  end # module
end # module
