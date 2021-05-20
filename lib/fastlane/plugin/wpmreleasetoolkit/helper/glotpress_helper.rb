require 'net/http'
require 'uri'

module Fastlane
  module Helper
    class GlotPressHelper
      # Gets the status of the translation for a given language.
      # 
      # @param [String] URL to the GlotPress project.
      # @param [String] The code of the language to get information about (GlotPress format).  
      #
      # @return [Integer] The percentage of the translated strings.
      #
      def self.get_translation_status(glotpress_url, language_code)
        uri = URI.parse(glotpress_url)
        response = Net::HTTP.get_response(uri)
        response = Net::HTTP.get_response(URI.parse(response.header['location'])) if response.code == '301'

        data = response.split("\n")
        current = extract_value_from_translation_info_data(data, language_code, 'current')
        fuzzy = extract_value_from_translation_info_data(data, language_code, 'fuzzy')
        untranslated = extract_value_from_translation_info_data(data, language_code, 'untranslated')
        waiting = extract_value_from_translation_info_data(data, language_code, 'waiting')

        (current / (current + fuzzy + untranslated + waiting)).round
      end

      def self.extract_value_from_translation_info_data(data, language_code, status)
        regex = "#{language_code}.*#{status}.*>([0-9,]+)"
        data.grep(/#{regex}/)[0].match(/#{regex}/)[1].gsub(/[,]/ ,"").to_i
      end
    end
  end 
end
