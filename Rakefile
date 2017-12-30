
require './lib/homebrew_automation/version'

task :default => [ :build ]

# Considering https://github.com/postmodern/rubygems-tasks
desc 'Build Gem'
task :build => [ :test ] do
  system 'gem build homebrew_automation.gemspec'
end

desc 'Run all tests'
task :test => :rspec

begin
  # https://relishapp.com/rspec/rspec-core/docs/command-line/rake-task
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:rspec)
rescue LoadError
end

def gem_path
  "homebrew_automation-#{HomebrewAutomation::VERSION}.gem"
end

