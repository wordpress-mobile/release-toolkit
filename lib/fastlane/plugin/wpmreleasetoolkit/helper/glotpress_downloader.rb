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

      # Takes a GlotPress JSON export and transform it to a simple `Hash` of key => value pairs
      #
      # Since the JSON format for GlotPress exports is a bit odd, with JSON keys actually being a concatenation of actual
      # copy key and source copy, and values being an array, this allows us to convert this odd export format to a more
      # usable structure.
      #
      # @param [#read] io The `File` or `IO` to read the JSON data exported from GlotPress
      def parse_json_export(io:)
        json = JSON.parse(io.read)
        json.map do |composite_key, values|
          key = composite_key.split(/\u0004/).first # composite_key is a concatenation of key + \u0004 + source]
          value = values.first # Each value in the JSON Hash is an Array of all the translations; but if we provided the right filter, the first one should always be the right one
          [key, value]
        end.to_h
      end
    end # class
  end # module
end # module
