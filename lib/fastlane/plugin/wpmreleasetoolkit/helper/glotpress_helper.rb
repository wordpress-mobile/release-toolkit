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
        # The status is parsed from Glotpress project page.
        # The row can be identified by the language code and the progress is in the column identified by the class "stats percent".
        # When the progress is above 90%, a special badge is added.
        # Because of the way the HTML is organized, this regex matches content spawned on three or four lines
        # Regex:
        # ^           : start of a line
        # \s*         : any space
        # <strong><a href=".*\/#{language_code}\/default\/"> : This link contains the language code of that line in the HTML table, so it's a reliable match
        # .*          : any character. The language name should be here, but it can be less reliable than the language code as a match
        # <\/strong>  : tag closure
        # \n          : new line
        # (?:         : match the following. This starts the "morethan90" special badge, which we expect to exist zero or one times (see the closure of this part of the regex).
        #       \s*         : any space
        #       <span class="bubble morethan90"> : Start of the special badge
        #       \d\d\d?%    : 2 or 3 digits and the percentage char
        #       <\/span>\n  : Special badge closure and new line
        # )?          : end of the "morethan90" special badge section. Expect this zero or one times.
        # \s*<\/td>\n : column closure tag. Any space before of it are ok. Expect new line after it.
        # \s*         : any space
        # <td class="stats percent"> : This is the tag which can be used to extract the progress
        # ([0-9]+)    : progress is the first group
        # %<\/td>     : tag closure
        regex = "^\\s*<strong><a href=\".*\\/#{language_code}\\/default\\/\">.*<\\/strong>\\n"
        regex += "(?:\\s*<span class=\"bubble morethan90\">\\d\\d\\d?%<\\/span>\\n)?\\s*<\\/td>\\n\\s*<td class=\"stats percent\">([0-9]+)%<\\/td>$"

        # 1. Merge the array into a single string.
        # 2. Match the info and extract the value in group 1.
        # 3. Convert to integer.
        data.join("\n").match(/#{regex}/)[1].to_i
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
