module Fastlane
  # Defines a single Locale with the various locale codes depending on the representation needed.
  #
  # The various locale codes formats for the various keys can be found as follows:
  #
  #  - glotpress:
  #      Go to the GP project page (e.g. https://translate.wordpress.org/projects/apps/android/dev/)
  #      and hover over the link for each locale, locale code is in the URL.
  #  - android: (`values-*` folder names)
  #       See https://developer.android.com/guide/topics/resources/providing-resources#AlternativeResources (Scroll to Table 2)
  #       [ISO639-1 (lowercase)]-r[ISO-3166-alpha-2 (uppercase)], e.g. `zh-rCN` ("Chinese understood in mainland China")
  #  - google_play: (PlayStore Console, for metadata, release_notes.xml and `fastlane supply`)
  #      See https://support.google.com/googleplay/android-developer/answer/9844778 (then open "View list of available languages").
  #      See also https://github.com/fastlane/fastlane/blob/master/supply/lib/supply/languages.rb
  #  - ios: (`*.lproj`)
  #      See https://developer.apple.com/documentation/xcode/choosing-localization-regions-and-scripts#Understand-the-Language-Identifier
  #      [ISO639-1/ISO639-2 (lowercase)]-[ISO 3166-1 (uppercase region or titlecase script)], e.g. `zh-Hans` ("Simplified Chinese" script)
  #  - app_store: (AppStoreConnect, for metadata and `fastlane deliver`)
  #      See https://github.com/fastlane/fastlane/blob/master/deliver/lib/deliver/languages.rb
  #
  # Links to ISO Standards
  #   ISO standard portal: https://www.iso.org/obp/ui/#search
  #   ISO 639-1: https://www.loc.gov/standards/iso639-2/php/code_list.php
  #   ISO-3166-alpha2: https://www.iso.org/obp/ui/#iso:pub:PUB500001:en
  #
  # Notes about region vs script codes in ISO-3166-1
  #   `zh-CN` is a locale code - Chinese understood in mainland China
  #   `zh-Hans` is a language+script code - Chinese written in Simplified Chinese (not just understood in mainland China)
  #
  Locale = Struct.new(:glotpress, :android, :google_play, :ios, :app_store, keyword_init: true) do
    # Returns the Locale with the given glotpress locale code from the list of all known locales (`Locales.all`)
    #
    # @param [String] The glotpress locale code for the locale to fetch
    # @return [Locale] The locale found
    # @raise [RuntimeException] if the locale with given glotpress code is unknown
    def self.[](code)
      Locales[code].first
    end
  end
end
