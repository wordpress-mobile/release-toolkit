class ChangelogParser
  PENDING_SECTION_TITLE = 'Trunk'.freeze
  EMPTY_PLACEHOLDER = '_None_'.freeze
  SUBSECTIONS_SEMVER_MAP = { 'Breaking Changes': 3, 'New Features': 2, 'Bug Fixes': 1, 'Internal Changes': 1 }.freeze

  def initialize(file: 'CHANGELOG.md')
    @lines = File.readlines(file)
    @current_index = nil
    @pending_section = nil
  end

  # @return the title of the section after the pending one -- which should match the latest released version
  def parse_pending_section
    (lines_before_first_section, _, title) = advance_to_next_header(level: 2)
    raise "Expected #{PENDING_SECTION_TITLE} as first section but found #{title} instead." unless title == PENDING_SECTION_TITLE

    subsections = []
    prev_subtitle = nil
    loop do
      (lines, next_level, next_subtitle) = advance_to_next_header(level: 2..3)
      subsections.append({ title: prev_subtitle, lines: lines }) unless lines.reject { |l| l.chomp.empty? || l.chomp == EMPTY_PLACEHOLDER }.empty?
      prev_subtitle = next_subtitle

      break if next_level < 3
    end
    @pending_section = { lines_before: lines_before_first_section, subsections: subsections, next_title: prev_subtitle }
    prev_subtitle
  end

  def cleaned_pending_changelog_lines
    lines = []
    @pending_section[:subsections].map do |s|
      lines.append "### #{s[:title]}\n" unless s[:title].nil? # subsection title is nil for lines between h2 and first h3
      lines += s[:lines]
    end
    lines
  end

  def guessed_next_semantic_version(current:)
    comps = current.split('.')
    idx_to_bump = 3 - semver_category
    comps[idx_to_bump] = (comps[idx_to_bump].to_i + 1).to_s
    ((idx_to_bump + 1)...(comps.length)).each { |i| comps[i] = '0' }
    comps.join('.')
  end

  def update_for_new_release(new_version:, new_file: 'CHANGELOG.md')
    raise 'You need to call #parse_pending_section first' if @pending_section.nil?

    File.open(new_file, 'w') do |f|
      f.puts @pending_section[:lines_before]
      # Empty placeholder section for next version after this one
      f.puts placeholder_section
      # Section for new version, with the non-empty subsections found while parsing first section
      f.puts "## #{new_version}\n\n"
      f.puts cleaned_pending_changelog_lines
      f.puts "## #{@pending_section[:next_title]}"
      f.puts read_up_to_end
    end
  end

  private

  # Advance line pointer to next index of provided `level`
  # @return [Array] A 3-item array of [scanned_lines, next_header_level, next_header_title]
  def advance_to_next_header(level:)
    range = level.is_a?(Range) ? level : level..level
    regex = /^(\#{#{range.min},#{range.max}}) ?([^#].*)$/ # A line starting with {range.min,range.max} times '#' then optional space then a title
    start_idx = @current_index.nil? ? 0 : @current_index + 1
    offset = @lines[start_idx...].index { |l| l =~ regex }
    @current_index = offset.nil? ? -1 : start_idx + offset

    m = regex.match(@lines[@current_index])
    [@lines[start_idx...@current_index], m[1].length, m[2]]
  end

  def read_up_to_end
    idx = @current_index + 1
    @current_index = -1
    @lines[idx...]
  end

  def placeholder_section
    lines = ["## #{PENDING_SECTION_TITLE}\n\n"]
    lines += SUBSECTIONS_SEMVER_MAP.keys.map { |s| "### #{s}\n\n#{EMPTY_PLACEHOLDER}\n\n" }
    lines.join
  end

  # @return the SemVer category (as described in Gem::Version doc). 3=major, 2=minor, 1=patch
  def semver_category
    raise 'You need to call #parse_pending_section first' if @pending_section.nil?

    @pending_section[:subsections].map { |s| SUBSECTIONS_SEMVER_MAP[s[:title].to_sym] || 1 }.max || 1
  end
end
