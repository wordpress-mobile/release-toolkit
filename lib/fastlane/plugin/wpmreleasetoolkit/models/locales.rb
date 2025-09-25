module Fastlane
  module Wpmreleasetoolkit
    class Locales
      ALL_KNOWN_LOCALES = [
        Locale.new(glotpress: 'ar',    android: 'ar',     playstore: 'ar'),
        Locale.new(glotpress: 'de',    android: 'de',     playstore: 'de-DE'),
        Locale.new(glotpress: 'en-gb', android: 'en-rGB', playstore: 'en-US'),
        Locale.new(glotpress: 'es',    android: 'es',     playstore: 'es-ES'),
        Locale.new(glotpress: 'fr-ca', android: 'fr-rCA', playstore: 'fr-CA'),
        Locale.new(glotpress: 'fr',    android: 'fr',     playstore: 'fr-FR', ios: 'fr-FR', appstore: 'fr-FR'),
        Locale.new(glotpress: 'he',    android: 'he',     playstore: 'iw-IL'),
        Locale.new(glotpress: 'id',    android: 'id',     playstore: 'id'),
        Locale.new(glotpress: 'it',    android: 'it',     playstore: 'it-IT'),
        Locale.new(glotpress: 'ja',    android: 'ja',     playstore: 'ja-JP'),
        Locale.new(glotpress: 'ko',    android: 'ko',     playstore: 'ko-KR'),
        Locale.new(glotpress: 'nl',    android: 'nl',     playstore: 'nl-NL'),
        Locale.new(glotpress: 'pl',    android: 'pl',     playstore: 'pl-PL'),
        Locale.new(glotpress: 'pt-br', android: 'pt-rBR', playstore: 'pt-BR', ios: 'pt-BR', appstore: 'pt-BR'),
        Locale.new(glotpress: 'ru',    android: 'ru',     playstore: 'ru-RU'),
        Locale.new(glotpress: 'sr',    android: 'sr',     playstore: 'sr'),
        Locale.new(glotpress: 'sv',    android: 'sv',     playstore: 'sv-SE'),
        Locale.new(glotpress: 'th',    android: 'th',     playstore: 'th'),
        Locale.new(glotpress: 'tr',    android: 'tr',     playstore: 'tr-TR'),
        Locale.new(glotpress: 'vi',    android: 'vi',     playstore: 'vi'),
        Locale.new(glotpress: 'zh-cn', android: 'zh-rCN', playstore: 'zh-CN', ios: 'zh-Hans', appstore: 'zh-Hans'),
        Locale.new(glotpress: 'zh-tw', android: 'zh-rTW', playstore: 'zh-TW', ios: 'zh-Hant', appstore: 'zh-Hant'),
        Locale.new(glotpress: 'az',    android: 'az'),
        Locale.new(glotpress: 'el',    android: 'el')
        # FIXME: Complete the list with ios/app_store properties for all, and extending to more locales
      ]

      MAG16_GP_CODES = %w[ar de es fr he id it ja ko nl pt-br ru sv tr zh-cn zh-tw].freeze

      ##############

      # [Array<Locale>]
      attr_accessor :locales

      # @param [Array<Locale>,Array<Hash>] locales
      def initialize(locales = ALL_KNOWN_LOCALES)
        @locales = locales.map { |l| l.is_a?(Locale) ? l : Locale.new(l) }
      end

      ##############
      # @!group Filter `Locales` based on locale codes

      # Return the list of locales matching the gp_codes passed as input parameters
      #
      # @param [String...] codes The locale codes to get the Locales for
      # @param [Symbol] key_name The name of the `Locale` property to use to filter those locales by.
      #        Defaults to `:glotpress` (= the `codes` param is expected to be _GlotPress_ locale codes by default)
      # @return [Locales]
      def self.[](*codes, key_name: :glotpress)
        locales = ALL_KNOWN_LOCALES.select { |l| codes.include?(l[key_name.to_sym]) }
        Locales.new(locales)
      end

      # Find a single given locale amongst the set of all known locales
      #
      # @param [String] code
      # @param [Symbol] key_name The name of the `Locale` property to use to filter those locales by.
      #        Defaults to `:glotpress` (= the `codes` param is expected to be _GlotPress_ locale codes by default)
      # @return [Locale?] The known locale matching the provided code, or `nil` if no known locale was found.
      def self.find(code, key_name: :glotpress)
        Locales.all.find(code, key_name: key_name)
      end

      # Find a single given locale amongst the set of locales registered in this `Locales` instance
      #
      # @param [String] code
      # @param [Symbol] key_name The name of the `Locale` property to use to filter those locales by.
      #        Defaults to `:glotpress` (= the `codes` param is expected to be _GlotPress_ locale codes by default)
      # @return [Locale?] The known locale matching the provided code, or `nil` if no known locale was found.
      def find(code, key_name: :glotpress)
        @locales.find { |l| code == l[key_name.to_sym] }
      end

      # @!endgroup
      ##############

      ##############
      # @!group Common locale sets

      def self.all
        Locales.new(ALL_KNOWN_LOCALES)
      end

      def self.mag16
        Locales[*MAG16_GP_CODES]
      end

      # @!endgroup
      ##############

      ##############
      # @!group Locales set arithmetics

      # Substraction
      def -(other)
        Locales.new(self.locales - other.locales)
      end

      # Intersection
      def &(other)
        Locales.new(self.locales & other.locales)
      end

      # Addition (without deduplication guarantee)
      def +(other)
        Locales.new(self.locales + other.locales)
      end

      # Union (with deduplication)
      def |(other)
        Locales.new(self.locales | other.locales)
      end

      # @!endgroup
      ##############

      ##############
      # @!group Conversion to other types and iteration

      def each
        @locales.each { |l| yield l }
      end

      # Constructs a `Hash` whose keys are the locale code for `key_sym` (e.g. `:glotpress`) and corresponding values are the locale code for `value_sym` (e.g. `:android`)
      # Example: `Locales.mag16.to_hash(:glotpress, :android)`
      def to_hash(key_sym, value_sym)
        Hash.new(
          @locales.map { |l| [l[key_sym], l[value_sym]] }
        )
      end

      def to_a
        if block_given?
          @locales.map { |l| yield l }
        else
          @locales
        end
      end

      def to_s
        "\#<Locales: [\n  #{@locales.join("\n  ")}\n]>"
      end

      # @!endgroup
      ##############
    end
  end
end
