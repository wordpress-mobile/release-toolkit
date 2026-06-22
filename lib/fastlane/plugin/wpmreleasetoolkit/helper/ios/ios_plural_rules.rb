# frozen_string_literal: true

module Fastlane
  module Helper
    module Ios
      # Maps a locale to the ordered list of CLDR plural categories that
      # correspond to the indexed plural forms a **GlotPress** `.po` export
      # carries for that locale (`msgstr[0]`, `msgstr[1]`, …).
      #
      # This is the bridge between two plural models:
      #
      # - **gettext** (`.po`/`.pot`, what GlotPress emits) addresses plural forms
      #   by numeric index. The number and meaning of those indices is defined by
      #   the locale's `Plural-Forms` formula and is *not* otherwise recorded.
      # - **iOS `.stringsdict`** addresses plural forms by CLDR category *name*
      #   (`zero`, `one`, `two`, `few`, `many`, `other`).
      #
      # ## How this table is derived
      #
      # The pipeline consumes `.po` files produced *by GlotPress*, so the source
      # of truth for how many forms exist (and in what order) is GlotPress's
      # `GP_Locales` definition, **not** the latest CLDR — the two disagree for
      # several locales (e.g. GlotPress keeps French/Spanish/Portuguese at two
      # forms, while CLDR added a compact-number `many`). This table is generated
      # by combining the two (see `rakelib/generate_ios_plural_rules.rb`):
      #
      # - **1 form** → `[other]` (the single category is always `other`).
      # - **2 forms** → `[one, other]` (gettext's universal 2-form naming).
      # - **3+ forms** → the locale's CLDR integer categories, in canonical
      #   order, **only when GlotPress's form count matches CLDR's**. When they
      #   disagree on a 3+-form locale (e.g. Welsh's legacy 4-form rule vs CLDR's
      #   6 categories) the locale is omitted on purpose — see {INCOMPATIBLE_LOCALES}
      #   and {UnknownLocaleError}. Guessing would silently file a translation
      #   under the wrong category.
      #
      # Because the count comes from GlotPress, the reverse converter also reads
      # `nplurals` from each `.po`'s own `Plural-Forms` header and asserts it
      # matches this table — so if GlotPress ever changes a locale's plural rule,
      # the run fails loudly (the signal to regenerate this table) rather than
      # producing wrong output. See {StringsdictHelper.generate_stringsdict_from_po}.
      #
      # @note Plural categories are a property of the *language*, so region
      #   subtags are ignored (`pt-BR`/`pt-PT` → `pt`). Lookups fall back from the
      #   full code to the base language.
      module PluralRules
        # Raised when asked for the plural categories of a locale we don't have a
        # vetted mapping for. Either the locale isn't in the table yet, or it's a
        # known GlotPress/CLDR incompatibility (see {INCOMPATIBLE_LOCALES}).
        class UnknownLocaleError < StandardError; end

        # Locales whose GlotPress plural rule cannot be honestly mapped to CLDR
        # `.stringsdict` categories. Looked up before the table so we can raise a
        # specific, actionable error instead of a generic "unknown locale".
        INCOMPATIBLE_LOCALES = {
          # GlotPress models Welsh with a legacy 4-form rule
          # `(n==1)?0:(n==2)?1:(n!=8&&n!=11)?2:3` whose indices don't correspond
          # to CLDR's six Welsh categories (zero/one/two/few/many/other), so there
          # is no correct index→category mapping.
          'cy' => 'GlotPress uses a legacy 4-form Welsh plural rule that does not map to CLDR categories'
        }.freeze

        # Locales grouped by their ordered category list, to keep the table
        # compact and reviewable. Generated — do not hand-edit; regenerate via
        # `rakelib/generate_ios_plural_rules.rb` (derived from GlotPress
        # `GP_Locales` nplurals + Unicode CLDR `plurals.xml`).
        CATEGORIES_BY_GROUP = {
          %i[other].freeze =>
            %w[bo ja ka km ko lo ms su th uz vi zh].freeze,
          %i[one other].freeze =>
            %w[af ak am an as ast az bal bg bho bm bn br brx ca ce ceb ckb cv da de dv ee el en eo es et eu
               fa fi fo fr fur fy gl gsw gu ha haw he hi hu hy ia id is it jv kab kk kn ks lb lij mg mk ml
               mn mr nb ne nl nn no nqo nso os pa pap pcm ps pt sah scn si so sq sv sw syr ta te tg tl tr
               tzm ug ur vec wa yi].freeze,
          %i[one few many].freeze =>
            %w[pl ru uk].freeze,
          %i[one few other].freeze =>
            %w[bs cs hr lt ro sk sr].freeze,
          %i[zero one other].freeze =>
            %w[lv].freeze,
          %i[one two few other].freeze =>
            %w[dsb gd hsb sl].freeze,
          %i[one two few many other].freeze =>
            %w[ga].freeze,
          %i[zero one two few many other].freeze =>
            %w[ar].freeze
        }.freeze

        # Locale (normalized) => ordered CLDR plural categories.
        CATEGORIES_BY_LOCALE = CATEGORIES_BY_GROUP.each_with_object({}) do |(categories, locales), hash|
          locales.each { |locale| hash[locale] = categories }
        end.freeze

        # The CLDR plural categories for a locale, ordered to match the GlotPress
        # `.po`'s `msgstr[N]` indices.
        #
        # @param [String] locale A locale code, e.g. `"en"`, `"pt-BR"`, `"ru"`.
        # @return [Array<Symbol>] Ordered categories, e.g. `%i[one few many]`.
        # @raise [UnknownLocaleError] if the locale (and its base language) has no
        #   vetted mapping, or is a known GlotPress/CLDR incompatibility.
        def self.categories_for(locale)
          key = normalize(locale)
          base = key.split('-').first

          incompatible = INCOMPATIBLE_LOCALES[key] || INCOMPATIBLE_LOCALES[base]
          raise(UnknownLocaleError, "No plural-category mapping for locale '#{locale}': #{incompatible}.") if incompatible

          CATEGORIES_BY_LOCALE[key] ||
            CATEGORIES_BY_LOCALE[base] ||
            raise(UnknownLocaleError, "No plural-category mapping for locale '#{locale}'. " \
                                      'Add it to Fastlane::Helper::Ios::PluralRules by regenerating the table ' \
                                      '(rakelib/generate_ios_plural_rules.rb) from GlotPress GP_Locales + CLDR.')
        end

        # Whether a vetted mapping exists for the given locale.
        # @param [String] locale A locale code.
        # @return [Boolean]
        def self.supported?(locale)
          key = normalize(locale)
          base = key.split('-').first
          return false if INCOMPATIBLE_LOCALES.key?(key) || INCOMPATIBLE_LOCALES.key?(base)

          CATEGORIES_BY_LOCALE.key?(key) || CATEGORIES_BY_LOCALE.key?(base)
        end

        # Normalize a locale code to the table's key form: lowercase, with `_`
        # treated as `-` (so `pt_BR` and `pt-BR` are equivalent).
        # @param [String] locale
        # @return [String]
        def self.normalize(locale)
          locale.to_s.strip.downcase.tr('_', '-')
        end
      end
    end
  end
end
