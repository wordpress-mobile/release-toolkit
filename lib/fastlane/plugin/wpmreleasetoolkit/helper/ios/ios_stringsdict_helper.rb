# frozen_string_literal: true

require 'plist'
require 'gettext/po'
require 'gettext/po_entry'
require 'gettext/po_parser'
require_relative 'ios_plural_rules'
require_relative '../../version'

module Fastlane
  module Helper
    module Ios
      # Converts between iOS `.stringsdict` plural files and gettext `.po`/`.pot`
      # files, so that string pluralization can round-trip through a translation
      # system (e.g. GlotPress) that speaks gettext but not `.stringsdict`.
      #
      # **Forward** ({generate_pot}): an English `.stringsdict` becomes a `.pot`
      # template. Each plural variable becomes one `msgid`/`msgid_plural` entry
      # (English `one` → `msgid`, English `other` → `msgid_plural`), keyed by a
      # deterministic `msgctxt`. Only `one`/`other` map to gettext; any other CLDR
      # category present in the source — most notably an explicit `zero` literal
      # override (which iOS honors even for English, e.g. "No items" for a count
      # of 0) — has no gettext slot and is dropped from the `.pot` with a warning.
      #
      # **Reverse** ({generate_stringsdict_from_po}): a translated `.po` for a
      # locale, plus the original English `.stringsdict` as a structural template,
      # become a localized `.stringsdict`. The `.po`'s indexed `msgstr[N]` forms
      # are mapped back to CLDR category names (`one`, `few`, `many`, …) using
      # {PluralRules}; everything that isn't a translatable plural form (the
      # format key, variable names, spec/value types) is copied from the template.
      #
      # @note The reverse direction reuses the **same English `.stringsdict`** that
      #   produced the `.pot`. The `.po` only carries the translatable strings; the
      #   structure comes from the template (mirroring how the Android downloader
      #   uses the original XML as a template).
      class StringsdictHelper
        # `.stringsdict` plist keys
        FORMAT_KEY = 'NSStringLocalizedFormatKey'
        SPEC_TYPE_KEY = 'NSStringFormatSpecTypeKey'
        VALUE_TYPE_KEY = 'NSStringFormatValueTypeKey'
        PLURAL_RULE_TYPE = 'NSStringPluralRuleType'

        # CLDR plural categories, in canonical emit order.
        CLDR_CATEGORIES = %w[zero one two few many other].freeze

        # gettext separates the plural forms of a single `POEntry#msgstr` with a
        # NUL byte (`msgstr[0]\0msgstr[1]\0…`).
        PLURAL_SEPARATOR = 0.chr

        # ===================================================================
        # I/O
        # ===================================================================

        # Read a `.stringsdict` file into its Hash representation.
        #
        # @param [String] path The path to the `.stringsdict` file.
        # @return [Hash] The parsed plist dictionary.
        # @raise [FastlaneCore::Interface::FastlaneError] If the file is missing, is not a plist
        #   dictionary, or contains an entry whose value is not a dictionary.
        def self.read(path:)
          UI.user_error!("Stringsdict file not found: #{path}") unless File.exist?(path)

          data = Plist.parse_xml(path)
          UI.user_error!("Invalid stringsdict file (expected a plist dictionary at the root): #{path}") unless data.is_a?(Hash)

          data.each do |key, value|
            UI.user_error!("Invalid stringsdict file (entry '#{key}' is not a dictionary): #{path}") unless value.is_a?(Hash)
          end

          data
        end

        # Write a Hash representation to a `.stringsdict` file in XML-plist format.
        #
        # @param [Hash] data The plist dictionary to serialize.
        # @param [String] path The destination path.
        def self.write(data:, path:)
          File.write(path, Plist::Emit.dump(data))
        end

        # ===================================================================
        # Forward: .stringsdict -> .pot
        # ===================================================================

        # Generate a gettext `.pot` template from one or more English
        # `.stringsdict` files.
        #
        # @param [String, Array<String>] stringsdict_paths One or more paths to
        #        source `.stringsdict` files.
        # @param [String] output_path The `.pot` file to write.
        # @return [Integer] The number of plural entries written.
        # @raise [FastlaneCore::Interface::FastlaneError] If two entries would produce the same `msgctxt`.
        def self.generate_pot(stringsdict_paths:, output_path:)
          po = GetText::PO.new
          po.order = :none
          add_header(po)

          entries = []
          seen_contexts = {}
          Array(stringsdict_paths).each do |path|
            read(path: path).each do |key, entry_dict|
              variables = plural_variables(entry_dict)
              single = variables.size == 1
              variables.each do |var_name, var_dict|
                context = context_for(key: key, variable: var_name, single_variable: single)
                if seen_contexts.key?(context)
                  UI.user_error!("Duplicate translation context '#{context}' generated from `#{path}` (also produced by " \
                                 "`#{seen_contexts[context]}`). Stringsdict keys must be unique across the files being converted.")
                end
                seen_contexts[context] = path
                entries << build_pot_entry(context: context, var_dict: var_dict, key: key, variable: var_name)
              end
            end
          end

          entries.sort_by(&:msgctxt).each { |entry| po[entry.msgctxt, entry.msgid] = entry }

          # GetText::PO#to_s does not add a trailing newline.
          File.write(output_path, "#{po}\n")
          entries.count
        end

        # ===================================================================
        # Reverse: .po + template -> localized .stringsdict
        # ===================================================================

        # Generate a localized `.stringsdict` from a translated `.po` plus the
        # English `.stringsdict` used as a structural template.
        #
        # @param [String] po_path The translated `.po` file for the locale.
        # @param [String] template_path The original English `.stringsdict`.
        # @param [String] locale The locale of the `.po` (e.g. `"ru"`, `"pt-BR"`),
        #        used to map `msgstr[N]` indices back to CLDR plural categories.
        # @param [String] output_path The localized `.stringsdict` to write.
        # @return [Array<String>] Contexts present in the template for which the
        #         `.po` had no usable translation (filled from English as fallback).
        # @raise [PluralRules::UnknownLocaleError] If the locale has no mapping.
        # @raise [FastlaneCore::Interface::FastlaneError] If a translated entry's form count
        #         doesn't match the locale's expected plural-category count.
        def self.generate_stringsdict_from_po(po_path:, template_path:, locale:, output_path:)
          template = read(path: template_path)
          po = parse_po(po_path)
          categories = Fastlane::Helper::Ios::PluralRules.categories_for(locale)

          # GlotPress is the source of truth for how many plural forms a locale
          # has. If the .po's own declared count disagrees with our mapping,
          # GlotPress has changed its plural rule for this locale — fail loud
          # (the signal to regenerate PluralRules) rather than silently mis-map.
          guard_po_plural_count!(parsed_po: po, locale: locale, categories: categories)

          missing = []
          result = {}
          template.each do |key, entry_dict|
            variables = plural_variables(entry_dict)
            if variables.empty?
              # Not a plural entry — copy verbatim.
              result[key] = entry_dict
              next
            end

            single = variables.size == 1
            localized = {}
            localized[FORMAT_KEY] = entry_dict[FORMAT_KEY] if entry_dict.key?(FORMAT_KEY)
            variables.each do |var_name, var_dict|
              context = context_for(key: key, variable: var_name, single_variable: single)
              forms = translated_forms(parsed_po: po, context: context, source_var: var_dict)
              if forms.empty?
                missing << context
                localized[var_name] = english_variable(var_dict)
              else
                validate_form_count!(forms: forms, categories: categories, context: context, locale: locale)
                warn_partial_translation(context: context, locale: locale, categories: categories, forms: forms)
                localized[var_name] = localized_variable(source_var: var_dict, categories: categories, forms: forms)
              end
            end
            result[key] = localized
          end

          write(data: result, path: output_path)
          missing
        end

        # ===================================================================
        # Helpers
        # ===================================================================

        # The plural variables of a `.stringsdict` entry: every sub-dictionary
        # (i.e. not the format-key string) whose spec type is the plural rule.
        #
        # @param [Hash] entry_dict A single `.stringsdict` entry.
        # @return [Hash{String=>Hash}] variable name => variable dictionary.
        def self.plural_variables(entry_dict)
          entry_dict.select do |k, v|
            k != FORMAT_KEY && v.is_a?(Hash) && v[SPEC_TYPE_KEY] == PLURAL_RULE_TYPE
          end
        end

        # The deterministic gettext `msgctxt` for a stringsdict key/variable.
        # Single-variable entries use the bare key (cleaner for translators);
        # multi-variable entries disambiguate with the variable name. Both the
        # forward and reverse directions call this, so the exact format is an
        # internal detail and never parsed back.
        #
        # @return [String]
        def self.context_for(key:, variable:, single_variable:)
          single_variable ? key : "#{key}:#{variable}"
        end

        # The English string that becomes a variable's gettext `msgid`: the `one`
        # form when it has content, otherwise `other`. Forward and reverse both
        # use this, so the `msgid` written to the `.pot` matches the one later
        # looked up in the translated `.po` — and an empty `one` no longer yields
        # an empty `msgid` (which gettext drops, silently losing the entry).
        def self.msgid_for(var_dict)
          one = var_dict['one']
          one.nil? || one.empty? ? var_dict['other'] : one
        end

        def self.build_pot_entry(context:, var_dict:, key:, variable:)
          singular = msgid_for(var_dict)
          plural = var_dict['other']
          if singular.nil? || singular.empty? || plural.nil? || plural.empty?
            UI.user_error!("Stringsdict entry '#{key}' is missing a required plural form " \
                           "(needs a non-empty 'other'; 'one' recommended for the singular).")
          end

          warn_dropped_categories(key: key, variable: variable, var_dict: var_dict)

          entry = GetText::POEntry.new(:msgctxt_plural)
          entry.msgctxt = context
          entry.msgid = singular
          entry.msgid_plural = plural
          # A template carries empty translations; English source has 2 forms.
          entry.msgstr = ['', ''].join(PLURAL_SEPARATOR)
          entry
        end

        # Only `one`/`other` survive the gettext round-trip (as `msgid`/
        # `msgid_plural`). Any other CLDR category in the source variable — most
        # commonly a `zero` literal override, which iOS honors even for English
        # (Apple's docs: an English `zero` returns "No homes found" for `0`) — has
        # no gettext equivalent and is dropped from the `.pot`. Warn so it isn't
        # lost silently.
        def self.warn_dropped_categories(key:, variable:, var_dict:)
          dropped = (CLDR_CATEGORIES - %w[one other]) & var_dict.keys
          return if dropped.empty?

          UI.important(
            "Stringsdict entry '#{key}' (variable '#{variable}') has plural form(s) " \
            "[#{dropped.join(', ')}] that gettext can't represent — they will be dropped " \
            "from the `.pot` and won't be translated. Only 'one' and 'other' round-trip; " \
            "handle a count-specific message (e.g. a 'zero'/empty-state string) as a dedicated " \
            'string selected in code (`if count == 0`), not as a plural key in a `.stringsdict` ' \
            'bound for this pipeline.'
          )
        end

        # The translated plural forms for a context, or `[]` if untranslated.
        def self.translated_forms(parsed_po:, context:, source_var:)
          entry = parsed_po[context, msgid_for(source_var)]
          return [] if entry.nil? || entry.msgstr.nil?

          forms = entry.msgstr.split(PLURAL_SEPARATOR, -1)
          # An entry present but fully empty (no translation yet) counts as missing.
          return [] if forms.all? { |f| f.nil? || f.empty? }

          forms
        end

        def self.validate_form_count!(forms:, categories:, context:, locale:)
          return if forms.size == categories.size

          UI.user_error!("Translation for '#{context}' has #{forms.size} plural form(s) but locale '#{locale}' " \
                         "expects #{categories.size} (#{categories.join(', ')}). The translation system's plural " \
                         'configuration for this locale does not match the expected CLDR categories.')
        end

        # A translated entry that has some — but not all — of its plural forms
        # filled still passes the count check. The blank categories are omitted
        # from the `.stringsdict`, so iOS falls back to another form for those
        # counts, silently showing the wrong plural. Surface it the way the
        # forward path surfaces dropped categories, rather than shipping it.
        def self.warn_partial_translation(context:, locale:, categories:, forms:)
          blank = categories.each_index.select { |i| forms[i].nil? || forms[i].to_s.empty? }.map { |i| categories[i] }
          return if blank.empty?

          UI.important(
            "Translation for '#{context}' (locale '#{locale}') is incomplete — the " \
            "#{blank.join(', ')} plural form(s) are untranslated; those counts will fall " \
            'back to another form. Finish the translation so every count shows the right plural.'
          )
        end

        # Build a localized variable dictionary by mapping indexed forms to CLDR
        # categories and copying structure from the source variable.
        def self.localized_variable(source_var:, categories:, forms:)
          by_category = {}
          categories.each_with_index do |category, index|
            value = forms[index]
            by_category[category.to_s] = value unless value.nil? || value.empty?
          end

          # `.stringsdict` requires the `other` category. When the locale's
          # gettext forms don't include it (e.g. ru/pl have one/few/many), fall
          # back to the last (catch-all) translated form.
          by_category['other'] ||= forms.reject { |f| f.nil? || f.empty? }.last

          variable = {}
          variable[SPEC_TYPE_KEY] = source_var[SPEC_TYPE_KEY] || PLURAL_RULE_TYPE
          variable[VALUE_TYPE_KEY] = source_var[VALUE_TYPE_KEY] if source_var.key?(VALUE_TYPE_KEY)
          CLDR_CATEGORIES.each do |category|
            variable[category] = by_category[category] if by_category.key?(category)
          end
          variable
        end

        # A copy of the source (English) variable, used as a fallback when a
        # translation is missing so the output `.stringsdict` stays valid.
        def self.english_variable(source_var)
          variable = {}
          variable[SPEC_TYPE_KEY] = source_var[SPEC_TYPE_KEY] || PLURAL_RULE_TYPE
          variable[VALUE_TYPE_KEY] = source_var[VALUE_TYPE_KEY] if source_var.key?(VALUE_TYPE_KEY)
          CLDR_CATEGORIES.each do |category|
            variable[category] = source_var[category] if source_var.key?(category)
          end
          variable
        end

        def self.parse_po(path)
          UI.user_error!("PO file not found: #{path}") unless File.exist?(path)

          po = GetText::PO.new
          GetText::POParser.new.parse(File.read(path), po)
          po
        end

        # The `nplurals` value declared in the `.po`'s `Plural-Forms` header
        # (GlotPress's authoritative form count for the locale), or `nil` if the
        # header is absent. Read from the parsed header entry, whose `msgstr`
        # holds only the header fields — so a stray `nplurals=` token elsewhere
        # in the file (a comment, a translated string) can't be mistaken for it.
        def self.declared_nplurals(parsed_po)
          header = parsed_po[nil, '']
          return nil if header.nil? || header.msgstr.nil?

          match = header.msgstr.match(/nplurals\s*=\s*(\d+)/)
          match && Integer(match[1])
        end

        # Fail loud if the `.po`'s declared plural-form count doesn't match the
        # number of CLDR categories we expect for the locale — i.e. GlotPress's
        # plural rule has drifted from {PluralRules}.
        def self.guard_po_plural_count!(parsed_po:, locale:, categories:)
          declared = declared_nplurals(parsed_po)
          return if declared.nil? || declared == categories.size

          UI.user_error!("Locale '#{locale}': the .po declares nplurals=#{declared}, but the expected plural mapping has " \
                         "#{categories.size} categor#{categories.size == 1 ? 'y' : 'ies'} (#{categories.join(', ')}). " \
                         "GlotPress's plural rule for this locale no longer matches the PluralRules table — regenerate it " \
                         '(rakelib/generate_ios_plural_rules.rb).')
        end

        def self.add_header(po_data)
          generator = "#{Fastlane::Wpmreleasetoolkit::NAME} #{Fastlane::Wpmreleasetoolkit::VERSION}"
          header_content = <<~HEADER
            MIME-Version: 1.0
            Content-Type: text/plain; charset=UTF-8
            Content-Transfer-Encoding: 8bit
            Plural-Forms: nplurals=2; plural=n != 1;
            X-Generator: #{generator}
          HEADER

          header = GetText::POEntry.new(:normal)
          header.msgid = ''
          header.msgstr = header_content
          po_data[header.msgctxt, header.msgid] = header
        end
      end
    end
  end
end
