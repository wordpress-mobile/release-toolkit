module Fastlane
  Locale = Struct.new(:glotpress, :android, :google_play, :ios, :app_store, keyword_init: true) do
    def self.[](code)
      Locales[code].first
    end
  end

  class Locales

    ###################
    ## Constants
    ALL_KNOWN_LOCALES = [
      Locale.new(glotpress: "ar",    android: "ar",     google_play: "ar"   ),
      Locale.new(glotpress: "de",    android: "de",     google_play: "de-DE"),
      Locale.new(glotpress: "en-gb", android: "en-rGB", google_play: "en-US"),
      Locale.new(glotpress: "es",    android: "es",     google_play: "es-ES"),
      Locale.new(glotpress: "fr-ca",    android: "fr-rCA", google_play: "fr-CA"),
      Locale.new(glotpress: "fr",    android: "fr",     google_play: "fr-FR"),
      Locale.new(glotpress: "he",    android: "he",     google_play: "iw-IL"),
      Locale.new(glotpress: "id",    android: "id",     google_play: "id"   ),
      Locale.new(glotpress: "it",    android: "it",     google_play: "it-IT"),
      Locale.new(glotpress: "ja",    android: "ja",     google_play: "ja-JP"),
      Locale.new(glotpress: "ko",    android: "ko",     google_play: "ko-KR"),
      Locale.new(glotpress: "nl",    android: "nl",     google_play: "nl-NL"),
      Locale.new(glotpress: "pl",    android: "pl",     google_play: "pl-PL"),
      Locale.new(glotpress: "pt-br", android: "pt-rBR", google_play: "pt-BR"),
      Locale.new(glotpress: "ru",    android: "ru",     google_play: "ru-RU"),
      Locale.new(glotpress: "sr",    android: "sr",     google_play: "sr"   ),
      Locale.new(glotpress: "sv",    android: "sv",     google_play: "sv-SE"),
      Locale.new(glotpress: "th",    android: "th",     google_play: "th"   ),
      Locale.new(glotpress: "tr",    android: "tr",     google_play: "tr-TR"),
      Locale.new(glotpress: "vi",    android: "vi",     google_play: "vi"   ),
      Locale.new(glotpress: "zh-cn", android: "zh-rCN", google_play: "zh-CN"),
      Locale.new(glotpress: "zh-tw", android: "zh-rTW", google_play: "zh-TW"),
      Locale.new(glotpress: "az",    android: "az"),
      Locale.new(glotpress: "el",    android: "el"),
      Locale.new(glotpress: "es-mx", android: "es-rMX"),
      Locale.new(glotpress: "es-cl", android: "es-rCL"),
      Locale.new(glotpress: "gd",    android: "gd"),
      Locale.new(glotpress: "hi",    android: "hi"),
      Locale.new(glotpress: "hu",    android: "hu"),
      Locale.new(glotpress: "nb",    android: "nb"),
      Locale.new(glotpress: "pl",    android: "pl"),
      Locale.new(glotpress: "th",    android: "th"),
      Locale.new(glotpress: "uz",    android: "uz"),
      Locale.new(glotpress: "zh-tw", android: "zh-rHK"),
      Locale.new(glotpress: "eu",    android: "eu"),
      Locale.new(glotpress: "ro",    android: "ro"),
      Locale.new(glotpress: "mk",    android: "mk"),
      Locale.new(glotpress: "en-au", android: "en-rAU"),
      Locale.new(glotpress: "sr",    android: "sr"),
      Locale.new(glotpress: "sk",    android: "sk"),
      Locale.new(glotpress: "cy",    android: "cy"),
      Locale.new(glotpress: "da",    android: "da"),
      Locale.new(glotpress: "bg",    android: "bg"),
      Locale.new(glotpress: "sq",    android: "sq"),
      Locale.new(glotpress: "hr",    android: "hr"),
      Locale.new(glotpress: "cs",    android: "cs"),
      Locale.new(glotpress: "pt-br", android: "pt-rBR"),
      Locale.new(glotpress: "en-ca", android: "en-rCA"),
      Locale.new(glotpress: "ms",    android: "ms"),
      Locale.new(glotpress: "es-ve", android: "es-rVE"),
      Locale.new(glotpress: "gl",    android: "gl"),
      Locale.new(glotpress: "is",    android: "is"),
      Locale.new(glotpress: "es-co", android: "es-rCO"),
      Locale.new(glotpress: "kmr",   android: "kmr")
    ].freeze

    MAG16_GP_CODES = %w[ar de es fr he id it ja ko nl pt-br ru sv tr zh-cn zh-tw].freeze

    ###################
    ## Static Methods

    class << self

      # @return [Array<Locale>] Array of all the known locales
      #
      def all
        ALL_KNOWN_LOCALES
      end

      # Define from_glotpress(code_or_list), from_android(code_or_list) … methods
      #
      # @param [Array<String>, String] list of locale codes to search for, or single value for single result
      # @return [Array<Locale>, Locale] list of found locales (empty if none found), or single locale if a single value was passed (or nil if not found)
      #
      %i[glotpress android google_play ios app_store].each do |key|
        define_method("from_#{key}") { |args| search(key, args) }
      end

      # Return an Array<Locale> based on glotpress locale codes
      #
      # @note If you need a single locale, you can use Locale[code] instead of Locales[code]
      # @param [String..., Array<String>] Arbitrary list of strings, either passed as a single array parameter, or as a vararg list of params
      # @return [Array<Locale>] The found locales.
      #
      def [](*list)
        # If we passed an Array, `*list` will make it an Array<Array<String>>, so taking `list.first` in those cases to go back to Array<String>
        list = list.first if list.count == 1 && list.first.is_a?(Array)
        from_glotpress(list)
      end

      # Return the subset of the 16 locales most of our apps are localized 100% (what we call the "Magnificent 16")
      #
      # @return [Array<Locale>] List of the Mag16 locales
      def mag16
        from_glotpress(MAG16_GP_CODES)
      end

      ###################

      private

      # Search the known locales for just the ones having the provided locale code, where the codes are expressed using the standard for the given key
      def search(key, code_or_list)
        if code_or_list.is_a?(Array)
          code_or_list.map { |code| search(key, code) }
        else # String
          raise 'The locale code should not contain spaces. Did you accidentally use `%[]` instead of `%w[]` at call site?' if code_or_list.include?(' ')
          ALL_KNOWN_LOCALES.find { |locale| locale.send(key) == code_or_list } || not_found(code_or_list, key)
        end
      end

      def not_found(code, key)
        raise "Unknown locale for #{key} code '#{code}'"
      end
    end
  end
end
