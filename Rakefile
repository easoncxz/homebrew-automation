
begin
  require 'rspec/core/rake_task'

  # https://relishapp.com/rspec/rspec-core/docs/command-line/rake-task
  RSpec::Core::RakeTask.new(:spec_lolz)

  task default: %w[ test ]
  task :test => :spec_lolz

rescue LoadError
end
