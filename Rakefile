
require './lib/homebrew_automation/version'

task :default => [ :build, :rtags ]

# Considering https://github.com/postmodern/rubygems-tasks
desc 'Build Gem'
task :build => [ :test ] do
  system 'gem build homebrew_automation.gemspec'
end

desc 'Run all tests'
task :test => [:rspec]

task :test_deps do
  if not system 'which http-echo-server'
    system 'npm -g install http-echo-server'
  end
end

desc 'Generate ctags file for vim'
task :rtags do
  system 'ripper-tags --recursive bin/ lib/'
end

begin
  # https://relishapp.com/rspec/rspec-core/docs/command-line/rake-task
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:rspec)
  task :rspec => :test_deps
rescue LoadError
end

task :tag do
  system 'git', 'tag', "v#{HomebrewAutomation::VERSION}"
end

task :docs do
  system 'rm', '-rf', '.yardoc/'
  system 'yard', 'server', '--reload'
end
