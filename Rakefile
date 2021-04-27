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

desc "Generate the docs using YARD"
task :doc do
  sh('yard', 'doc')
  # Open generated doc in browser
  sh('open', 'yard-doc/index.html')
end

desc "Print stats about undocumented methods. Provide an optional path relative to 'lib/fastlane/plugin/wpmreleasetoolkit' to only show stats for that subdirectory"
task :docstats, [:path] do |_,args|
  path = File.join('lib/fastlane/plugin/wpmreleasetoolkit', args[:path] || '.')
  sh('yard', 'stats', '--list-undoc', path)
end

Rake::ExtensionTask.new('drawText')
