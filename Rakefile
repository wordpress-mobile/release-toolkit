require 'rake'

begin
  require 'rubocop/rake_task'
  require 'rake/extensiontask'

rescue LoadError
  abort 'Please run this task using `bundle exec rake`'
end

RuboCop::RakeTask.new
task default: %i[spec rubocop]

Rake::ExtensionTask.new('drawText')
