# frozen_string_literal: true

# Regenerates the locale → CLDR-plural-category table baked into
# `lib/fastlane/plugin/wpmreleasetoolkit/helper/ios/ios_plural_rules.rb`.
#
# The `.stringsdict ⇆ .po` pipeline consumes `.po` files produced by GlotPress,
# so GlotPress's `GP_Locales` is the source of truth for *how many* plural forms
# a locale has; Unicode CLDR is the source of truth for the *names* of those
# categories. This script combines the two:
#
#   - 1 form            → [other]
#   - 2 forms           → [one, other]   (gettext's universal 2-form naming)
#   - 3+ forms          → the locale's CLDR integer categories (canonical order),
#                         ONLY when GlotPress's form count equals CLDR's. When
#                         they disagree (e.g. Welsh's legacy 4-form rule vs CLDR's
#                         6 categories) the locale is omitted on purpose — the
#                         converter then fails loud rather than guessing.
#
# A locale is also omitted when GlotPress addresses it under a different slug
# than CLDR (e.g. Belarusian is `bel` in GlotPress vs `be` in CLDR) — see
# `nplurals_for`. These too fail loud rather than mis-map; none are in SHIPPED.
#
# Inputs are vendored under rakelib/plural_rules_data/ for offline reproducibility:
#   - cldr_plurals.xml        — Unicode CLDR common/supplemental/plurals.xml
#   - glotpress_nplurals.json — { slug => nplurals } from GlotPress GP_Locales
#
# Usage:
#   bundle exec ruby rakelib/generate_ios_plural_rules.rb
#
# Review the printed CATEGORIES_BY_GROUP block, then paste it into
# ios_plural_rules.rb. Re-run whenever CLDR or GlotPress's plural data changes
# (the reverse converter's `.po` count-guard tells you when that has happened).

require 'json'
require 'nokogiri'

DATA_DIR = File.join(__dir__, 'plural_rules_data')
CANONICAL_ORDER = %w[zero one two few many other].freeze
# Locales the apps ship, for a coverage report.
SHIPPED = %w[ar bg cs cy da de en es fr he hr hu id is it ja ko nb nl pl pt ro ru sk sq sv th tr zh].freeze

# A CLDR category is a "counting" category if it has an @integer sample whose
# smallest value is <= 100 — this excludes compact-only categories (Romance
# `many`, sampled only at 1000000/1c6) and decimal-only categories.
def counting_category?(rule_text)
  m = rule_text.match(/@integer([^@]*)/)
  return false unless m

  m[1].split(',').any? do |tok|
    tok = tok.strip.chomp('…').strip
    next false if tok.empty? || tok.include?('…') || tok.include?('c') || tok.include?('e')

    Integer(tok.split('~').first, exception: false).then { |v| v && v <= 100 }
  end
end

def cldr_integer_categories
  doc = Nokogiri::XML(File.read(File.join(DATA_DIR, 'cldr_plurals.xml')))
  table = {}
  doc.xpath('//plurals[@type="cardinal"]/pluralRules').each do |group|
    cats = group.xpath('./pluralRule').select { |r| counting_category?(r.text) }.map { |r| r['count'] }
    ordered = CANONICAL_ORDER.select { |c| cats.include?(c) }
    group['locales'].split.each { |loc| table[loc] = ordered }
  end
  table
end

def glotpress_nplurals
  JSON.parse(File.read(File.join(DATA_DIR, 'glotpress_nplurals.json')))
end

# GlotPress's plural-form count for a CLDR locale code. CLDR and GlotPress
# usually agree on slugs, but not always: GlotPress addresses some languages by
# an ISO-639-2/3 code where CLDR uses the 639-1 code (Belarusian is `bel` in
# GlotPress vs `be` in CLDR; likewise `mya`/`my`, `dzo`/`dz`, `wol`/`wo`, …). We
# only try the CLDR code and its regional variants, so those locales return
# `nil` here and are omitted from the table — they then fail loud
# (UnknownLocaleError) at runtime rather than being mis-mapped. None are in the
# apps' shipped set today; to support one, add a vetted CLDR→GlotPress alias
# here — a literal mapping, NOT a prefix match (`sc`→`scn` is Sardinian vs
# Sicilian, `ve`→`vec` is Venda vs Venetian, so prefix-guessing is unsafe).
def nplurals_for(base, glotpress)
  glotpress[base] || glotpress[glotpress.keys.sort.find { |slug| slug.start_with?("#{base}-") }]
end

cldr = cldr_integer_categories
glotpress = glotpress_nplurals

table = {}
omitted = []
cldr.sort.each do |locale, cats|
  next if locale.include?('_') || locale == 'root'

  n = nplurals_for(locale, glotpress)
  if n.nil?
    omitted << [locale, 'not in GlotPress', cats]
  elsif n == 1
    table[locale] = %w[other]
  elsif n == 2
    table[locale] = %w[one other]
  elsif n == cats.size
    table[locale] = cats
  else
    omitted << [locale, "GlotPress #{n} != CLDR #{cats.size}", cats]
  end
end

groups = table.group_by { |_locale, cats| cats }.transform_values { |pairs| pairs.map(&:first).sort }

puts '# --- paste into ios_plural_rules.rb (CATEGORIES_BY_GROUP) ---'
puts 'CATEGORIES_BY_GROUP = {'
groups.keys.sort_by { |cats| [cats.size, cats] }.each do |cats|
  syms = "%i[#{cats.join(' ')}].freeze"
  locales = "%w[#{groups[cats].join(' ')}].freeze"
  puts "  #{syms} =>\n    #{locales},"
end
puts '}.freeze'

puts "\n# --- report ---"
puts "# generated #{table.size} locales, omitted #{omitted.size} (fail loud at runtime)"
shipped_omitted = omitted.map(&:first) & SHIPPED
puts "# shipped locales omitted: #{shipped_omitted.empty? ? '(none)' : shipped_omitted.join(', ')}"
SHIPPED.each do |loc|
  mapped = table[loc] ? table[loc].join('/') : 'OMITTED (fail loud)'
  puts "#   #{loc.ljust(4)} #{mapped}"
end
