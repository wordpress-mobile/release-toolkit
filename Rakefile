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


GEM_NAME = 'fastlane-plugin-wpmreleasetoolkit'.freeze
VERSION_FILE = File.join('lib', 'fastlane', 'plugin', 'wpmreleasetoolkit', 'version.rb')

desc 'Try to build and install the gem to ensure it can be installed properly (with the native extension and all)'
task :check_install_gem do
  require_relative(VERSION_FILE)
  version = Fastlane::Wpmreleasetoolkit::VERSION
  sh('gem', 'build', "#{GEM_NAME}.gemspec")
  sh('gem', 'uninstall', GEM_NAME, '-v', version)
  sh('gem', 'install', "#{GEM_NAME}-#{version}.gem")
end

desc 'Create a new version of the release-toolkit gem'
task :new_release do
  require_relative(VERSION_FILE)

  parser = ChangelogParser.new(file: 'CHANGELOG.md')
  latest_version = parser.parse_pending_section

  ## Print current info
  puts ">>> Current version is: #{Fastlane::Wpmreleasetoolkit::VERSION}"
  puts "Warning: Latest version number does not match latest version title in CHANGELOG (#{latest_version})!" unless Fastlane::Wpmreleasetoolkit::VERSION == latest_version

  puts ">>> Pending CHANGELOG:\n\n#{parser.cleaned_pending_changelog_lines.map { |l| "| #{l}"}.join}\n"

  ## Prompt for next version number
  guess = parser.guessed_next_semantic_version(current: Fastlane::Wpmreleasetoolkit::VERSION)
  print ">>> New version to release [#{guess}]? "
  new_version = STDIN.gets.chomp
  new_version = guess if new_version.empty?

  ## Checkout branch, update files and commit
  check_or_create_branch(new_version)
  update_version_constant(VERSION_FILE, new_version)
  parser.update_for_new_release(new_version: new_version)
  sh('git', 'add', VERSION_FILE, 'Gemfile.lock', 'CHANGELOG.md')
  sh('git', 'commit', '-m', "Bumped to version #{new_version}")

  ## Ensure the gem builds and is installable
  puts ">>> Testing that the gem builds and installs..."
  Rake::Task['check_install_gem'].invoke([new_version])

  puts ">>> Opening PR drafts in your default browser..."
  prepare_github_pr("release/#{new_version}", 'develop', "Release #{new_version} into develop", "New version #{new_version}")
  prepare_github_pr("release/#{new_version}", 'trunk', "Release #{new_version} into trunk", "New version #{new_version}. Be sure to create a GitHub Release and tag once this PR gets merged.")

  puts <<~INSTRUCTIONS

    ---------------

    >>> WHAT'S NEXT

    1. Create PRs to `develop` and `trunk`.
    2. Once the PRs are merged, create a GH release for \`#{new_version}\` targeting \`trunk\`,
       creating a new \`#{new_version} tag in the process.

    The creation of the new tag will trigger a CI workflow that will take care of doing the
    \`gem push\` of the new version to RubyGems.

  INSTRUCTIONS
end

########################
# Helpers
########################

def check_or_create_branch(new_version)
  current_branch = `git branch --show-current`.chomp
  release_branch = "release/#{new_version}"
  if current_branch == release_branch
    puts "Already on release branch"
  else
    sh('git', 'checkout', '-b', release_branch)
  end
end

def prepare_github_pr(head, base, title, body)
  require 'open-uri'
  qtitle = title.gsub(' ', '%20')
  qbody = body.gsub(' ', '%20')
  uri = URI.parse("https://github.com/wordpress-mobile/release-toolkit/compare/#{base}...#{head}?expand=1&title=#{qtitle}&body=#{qbody}")
  uri.open
end

def update_version_constant(version_file, new_version)
  puts '>>> Updating `VERSION` constant in `version.rb`...'
  content = File.read(version_file)
  content.gsub!(/VERSION = .*/, "VERSION = '#{new_version}'")
  File.write(version_file, content)

  sh('bundle', 'install') # To update Gemfile.lock with new wpmreleasetoolkit version
end

