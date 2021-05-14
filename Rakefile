require 'rake'

begin
  require 'rubocop/rake_task'
  require 'rake/extensiontask'
rescue LoadError
  abort 'Please run this task using `bundle exec rake`'
end

task default: %i[test rubocop]

RuboCop::RakeTask.new

desc 'Run the unit tests using rspec'
task :test do
  sh('rspec')
end

desc 'Generate the docs using YARD'
task :doc do
  sh('yard', 'doc')
  # Open generated doc in browser
  sh('open', 'yard-doc/index.html')
end

desc "Print stats about undocumented methods. Provide an optional path relative to 'lib/fastlane/plugin/wpmreleasetoolkit' to only show stats for that subdirectory"
task :docstats, [:path] do |_, args|
  path = File.join('lib/fastlane/plugin/wpmreleasetoolkit', args[:path] || '.')
  sh('yard', 'stats', '--list-undoc', path)
end

Rake::ExtensionTask.new('drawText')

desc 'Create a new version of the release-toolkit gem'
task :new_release do
  version_file = File.join('lib', 'fastlane', 'plugin', 'wpmreleasetoolkit', 'version.rb')
  require_relative(version_file)
  puts ">>> Current version is: #{Fastlane::Wpmreleasetoolkit::VERSION}"
  puts ">>> Pending CHANGELOG:\n" + get_changelog_section(file: 'CHANGELOG.md', section_title: 'Develop').map { |l| "| #{l}" }.join

  puts '>>> New version to use?'
  new_version = STDIN.gets.chomp

  ### VERSION constant
  puts '>>> Updating `VERSION` constant in `version.rb`...'
  content = File.read(version_file)
  content.gsub!(/VERSION = .*/, "VERSION = '#{new_version}'")
  File.write(version_file, content)
  sh('bundle', 'install') # To update Gemfile.lock with new wpmreleasetoolkit version

  ### CHANGELOG.md
  puts '>>> Updating the `CHANGELOG.md` file...'
  update_changelog_sections(
    file: 'CHANGELOG.md',
    wip_header_title: 'Develop',
    placeholder_sections: ['Breaking Changes', 'New Features', 'Bug Fixes', 'Internal Changes'],
    new_section_title: new_version
  )

  puts <<~INSTRUCTIONS

    ---------------

    >>> WHAT'S NEXT

    Please check that the version bump and CHANGELOG.md updates looks ok.
    Then, commit the changes in a new `release/#{new_version}` branch and create PRs to `develop` and `trunk`.

    Once the PRs are merged, create a GH release for `#{new_version}` targeting `trunk`,
    then run `gem build` and `gem push` to upload the version to RubyGems.
  INSTRUCTIONS
end

########################
# Helpers
########################

def next_index(matching:, after: 0, in_lines:)
  idx = in_lines[(after + 1)...].index { |l| l =~ matching }
  return -1 if idx.nil?

  idx + after + 1
end

def get_changelog_section(file:, section_title:)
  lines = File.readlines(file)
  section_start = next_index(matching: /^\#\# #{section_title}$/, in_lines: lines)
  section_end = next_index(matching: /^\#\# /, after: section_start, in_lines: lines)
  puts "#{section_start}...#{section_end}"
  lines[section_start...section_end]
end

def update_changelog_sections(file:, wip_header_title:, placeholder_sections:, empty_section_text: '_None_', new_section_title:)
  lines = File.readlines(file)

  # Find on which line the WIP h2 section starts
  wip_section_idx = next_index(matching: /^\#\# #{wip_header_title}$/, in_lines: lines)
  raise "#{wip_header_title} section not found in current CHANGELOG!" if wip_section_idx.nil?

  # Update CHANGELOG
  File.open(file, 'w') do |f|
    # Insert any preamble lines that exists before wip_header_title h2 section
    f.puts lines[0...wip_section_idx]

    # Insert the empty section placeholders for the next version
    f.puts ["\#\# #{wip_header_title}", '']
    placeholder_sections.each { |s| f.puts ["\#\#\# #{s}", '', empty_section_text, ''] }

    # Insert h2 section title for the new version we're releasing (in place of the old wip_header_title that was used for that h2 section until now)
    f.puts "\#\# #{new_section_title}"

    # Then print any subsequent h3 section that was in that wip section before... but omitting the ones that are empty
    current_idx = wip_section_idx + 1 # First line we start our analysis from, to iterate over each h3 subsection and prune the empty ones
    next_idx = 0
    loop do
      next_idx = next_index(matching: /^\#\#/, after: current_idx, in_lines: lines) # Index of next h2 or h3 section to stop at
      section_lines = lines[current_idx...next_idx] # lines from current_idx (aka subsection title) including, up to but non including next_idx (aka next section's title)
      body_lines = section_lines.drop(1).reject { |l| l.chomp.empty? } # non-empty lines in the current h3 section
      f.puts section_lines unless body_lines.empty? || body_lines.first.chomp == empty_section_text # only print section title+body if it wasn't empty
      break if next_idx == -1 || lines[next_idx].start_with?('## ') # if next section is h2 and not h3 (or we reached end of file), we're finally done with the WIP h2 section and reached the next h2 (for the previous released version)

      current_idx = next_idx
    end

    # Finally, print all the rest, i.e. everything that was after the WIP section, unprocessed.
    f.puts lines[next_idx...]
  end
end
