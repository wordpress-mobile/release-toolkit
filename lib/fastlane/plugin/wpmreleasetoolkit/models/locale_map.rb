module Fastlane
  # A struct describing the different codes for a single locale used by different services
  #
  # @param [String] ios The locale code used in `<code>.lproj` folder names on iOS
  # @param [String] app_store The locale code used in App Store Connect (e.g. for uploading store metadata)
  # @param [String] android The locale code used in `values-<code>/strings.xml` folder names on Android
  # @param [String] google_play The locale code used in Google Play Console (e.g. for uploading store metadata)
  # @param [String] glotpress The locale code in GlotPress
  # @param [String] onesky The locale code in OneSky (oneskyapp.com)
  #
  LocaleMap = Struct.new(:ios, :app_store, :android, :google_play, :glotpress, :onesky, keyword_init: true)

  # A class to register and access known `LocaleMap` objects easily
  #
  class LocalesMap
    # [Array<LocaleMap>] The list of locales maps this LocalesMap contains
    attr_reader :locales

    # @param [Array<Hash|LocaleMap>] list An array of LocaleMap objects, or an array of Hashes whose keys are the same ones as the members of LocaleMap
    #
    def initialize(list)
      @locales = list.map do |item|
        if item.is_a?(Hash)
          LocaleMap.new(**item)
        elsif item.is_a?(LocaleMap)
          item
        else
          raise "Invalid item #{item} in `LocalesMap.new` parameter: expected `Hash` or `LocaleMap`, but found #{item.class}."
        end
      end
    end

    # Returns a Hash indexed by the `key_sym` locale codes and with values for the `value_sym` locale code
    #
    # @param [Symbol] key_sym The symbol to indicate which locale code type to use as keys of the Hash. Should be one of `LocaleMap.members`
    # @param [Symbol] value_sym The symbol to indicate which locale code type to use as values of the Hash. Should be one of `LocaleMap.members`.
    #        If no `value_sym` is specified (or `:itself`), the returned `Hash`'s values will be `LocaleMap` objects in full (instead of just a `String` locale code)
    #
    # @return a Hash whose keys and values are derived from the corresponding attributes of each `LocaleMap` object of this `LocalesMap`
    #
    # @example `to_h(:onesky, :ios)` will return a `Hash` whose keys are the locale code for :onesky and values are the corresponding locale code for :ios
    # @example `to_h(:ios)` will return a `Hash` whose keys are the locale code for :ios and values are the corresponding `LocaleMap` objects
    # @note Any key or value that is nil (i.e. any LocaleMap which does not have a locale code defined for either that `key_sym` or `value_sym`) will be filtered out
    #
    def to_h(key_sym, value_sym = :itself)
      @locales.to_h do |lm|
        key = lm.send(key_sym)
        [key, key.nil? ? nil : lm.send(value_sym)]
      end.compact
    end

    # Returns an Array of locale codes for the `key_sym` service/context
    #
    # @param [Symbol] key_sym The symbol to indicate which locale code type to use for the values of the produced Array. Should be one of `LocaleMap.members`.
    #                 If no `key_sym` is specified (or `:to_h`), will return an `Array` of `Hash` representations of the `LocaleMap` objects
    # @return an Array whose values are derived from the corresponding attribute of each `LocaleMap` object of this `LocalesMap`
    #
    # @example `to_a(:ios)` will return an `Array` whose items are the locale code for `:ios`
    # @example `to_a(:to_h)` will return an `Array` whose items are the `Hash` representation of each `LocaleMap` object
    # @note `to_a` (aka `to_a(:itself)`) will return the same as `locales`
    # @note Any value that is nil (i.e. any LocaleMap which does not have a locale code defined for that `key_sym`) will be filtered out
    #
    def to_a(key_sym = :to_h)
      @locales.map { |lm| lm.send(key_sym) }.compact
    end

    # Returns a new `LocalesMap` object only keeping the `LocaleMap` objects for which the `block` returns true
    # @example `locales_map.select { |l| ['fr', 'es'].include?(l.ios) }
    def select(&block)
      LocalesMap.new(@locales.select(block))
    end

    def reject(&block)
      LocalesMap.new(@locales.reject(block))
    end

    def each(&block)
      @locales.each(block)
    end

    # Convert a locale code from one service/context to another
    #
    # @param [String] locale The locale code to convert
    # @param [Symbol] from The service/context to convert the locale from. Should be one of `LocaleMap.members`
    # @param [Symbol] to The service/context to convert the locale to. Should be one of `LocaleMap.members`
    #
    def convert(locale:, from:, to:)
      @locales.find { |lm| lm.send(from) == locale }&.send(to)
    end

    # The set of common locale codes mappings known to us
    #
    def self.default
      # TODO: Add :android locale codes
      # TODO: Add :glotpress locale codes
      LocalesMap.new(
        [
          LocaleMap.new(ios: 'en',         app_store: 'en-US',   google_play: 'en-US', onesky: 'en'),
          LocaleMap.new(ios: 'de',         app_store: 'de-DE',   google_play: 'de-DE', onesky: 'de'),
          LocaleMap.new(ios: 'es',         app_store: 'es-ES',   google_play: 'es-ES', onesky: 'es'),
          LocaleMap.new(ios: 'fr',         app_store: 'fr-FR',   google_play: 'fr-FR', onesky: 'fr'),
          LocaleMap.new(ios: 'hi',         app_store: 'hi',      google_play: 'hi-IN', onesky: 'hi'),
          LocaleMap.new(ios: 'id',         app_store: 'id',      google_play: 'id',    onesky: 'id'),
          LocaleMap.new(ios: 'it',         app_store: 'it',      google_play: 'it-IT', onesky: 'it'),
          LocaleMap.new(ios: 'ja',         app_store: 'ja',      google_play: 'ja-JP', onesky: 'ja'),
          LocaleMap.new(ios: 'ko',         app_store: 'ko',      google_play: 'ko-KR', onesky: 'ko'),
          LocaleMap.new(ios: 'nl',         app_store: 'nl-NL',   google_play: 'nl-NL', onesky: 'nl'),
          LocaleMap.new(ios: 'pl',         app_store: 'pl',      google_play: 'pl-PL', onesky: 'pl'),
          LocaleMap.new(ios: 'pt-PT',      app_store: 'pt-PT',   google_play: 'pt-PT', onesky: 'pt-PT'),
          LocaleMap.new(ios: 'pt',         app_store: 'pt-BR',   google_play: 'pt-BR', onesky: 'pt-BR'),
          LocaleMap.new(ios: 'ru',         app_store: 'ru',      google_play: 'ru-RU', onesky: 'ru'),
          LocaleMap.new(ios: 'tr',         app_store: 'tr',      google_play: 'tr-TR', onesky: 'tr'),
          LocaleMap.new(ios: 'zh-Hans',    app_store: 'zh-Hans', google_play: 'zh-CN', onesky: 'zh-CN'),
          LocaleMap.new(ios: 'zh-Hant-HK', app_store: nil,       google_play: nil,     onesky: 'zh-HK'),
          LocaleMap.new(ios: 'zh-Hant',    app_store: 'zh-Hant', google_play: 'zh-CN', onesky: 'zh-TW'),
        ]
      )
    end
  end
end
