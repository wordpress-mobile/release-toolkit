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
  Console.header "Current version is: #{Fastlane::Wpmreleasetoolkit::VERSION}"
  Console.warning "Warning: Latest version number does not match latest version title in CHANGELOG (#{latest_version})!" unless Fastlane::Wpmreleasetoolkit::VERSION == latest_version

  Console.header 'Pending CHANGELOG:'
  Console.print_indented_lines(parser.cleaned_pending_changelog_lines)

  ## Prompt for next version number
  guess = parser.guessed_next_semantic_version(current: Fastlane::Wpmreleasetoolkit::VERSION)
  new_version = Console.prompt('New version to release', guess)

  ## Checkout branch, update files
  GitHelper.check_or_create_branch(new_version)
  Console.header 'Update `VERSION` constant in `version.rb`...'
  update_version_constant(VERSION_FILE, new_version)
  Console.header 'Updating CHANGELOG...'
  parser.update_for_new_release(new_version: new_version)

  ## Ensure the gem builds and is installable
  Console.header 'Testing that the gem builds and installs...'
  Rake::Task['check_install_gem'].invoke([new_version])

  # Commit and push
  GitHelper.commit_files("Bumped to version #{new_version}", [VERSION_FILE, 'Gemfile.lock', 'CHANGELOG.md'])

  Console.header 'Opening PR drafts in your default browser...'
  GitHelper.prepare_github_pr("release/#{new_version}", 'develop', "Release #{new_version} into develop", "New version #{new_version}")
  GitHelper.prepare_github_pr("release/#{new_version}", 'trunk', "Release #{new_version} into trunk", "New version #{new_version}. Be sure to create a GitHub Release and tag once this PR gets merged.")

  Console.info <<~INSTRUCTIONS

    ---------------

    >>> WHAT'S NEXT

    1. Create PRs to `develop` and `trunk`.
    2. Once the PRs are merged, publish a GitHub release for \`#{new_version}\`, targeting \`trunk\`,
       creating a new \`#{new_version} tag in the process.

    The creation of the new tag will trigger a CI workflow that will take care of doing the
    \`gem push\` of the new version to RubyGems.

  INSTRUCTIONS
end

def update_version_constant(version_file, new_version)
  content = File.read(version_file)
  content.gsub!(/VERSION = .*/, "VERSION = '#{new_version}'")
  File.write(version_file, content)

  sh('bundle', 'install') # To update Gemfile.lock with new wpmreleasetoolkit version
end
