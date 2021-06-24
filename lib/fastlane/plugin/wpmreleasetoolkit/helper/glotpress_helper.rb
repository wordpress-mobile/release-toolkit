require 'net/http'
require 'uri'

module Fastlane
  module Helper
    class GlotPressHelper
      # Gets the data about status of the translation.
      #
      # @param [String] URL to the GlotPress project.
      #
      # @return [Array] Data from GlotPress project overview page.
      #
      def self.get_translation_status_data(glotpress_url:)
        uri = URI.parse(glotpress_url)
        response = Net::HTTP.get_response(uri)
        response = Net::HTTP.get_response(URI.parse(response.header['location'])) if response.code == '301'

        response.body.split("\n")
      end

      # Gets the status of the translation for a given language.
      #
      # @param [Array] Data from GlotPress project overview page.
      # @param [String] The code of the language to get information about (GlotPress format).
      #
      # @return [Integer] The percentage of the translated strings.
      #
      def self.get_translation_status(data:, language_code:)
        regex = "<strong><a href=\".*\/#{language_code}\/default\/\">.*<\/strong>\n<span.*>([0-9]+)%<\/span>"

        # 1. Grep the line with contains the required info.
        # 2. Match the info and extract the value in group 1.
        # 3. Convert to integer.
        puts data
        data.grep(/#{regex}/)[0].match(/#{regex}/)[1].to_i
      end

      # Extract the number of strings which are in the given status.
      #
      # @param [Array] Data from GlotPress project overview page.
      # @param [String] The code of the language to get information about (GlotPress format).
      # @param [String] The status which data should be extracted for.
      #
      # @return [Integer] The percentage of the translated strings.
      #
      def self.extract_value_from_translation_info_data(data:, language_code:, status:)
        regex = "\/#{language_code}\/.*#{status}.*>([0-9,]+)"

        # 1. Grep the line with contains the required info.
        # 2. Match the info and extract the value in group 1.
        # 3. Values use comma as thousands separator, so remove it.
        # 4. Convert to integer.
        data.grep(/#{regex}/)[0].match(/#{regex}/)[1].gsub(/,/, '').to_i
      end
    end
  end
end
