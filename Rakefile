
require './lib/homebrew_automation/version'

begin
  require 'rspec/core/rake_task'

  # https://relishapp.com/rspec/rspec-core/docs/command-line/rake-task
  RSpec::Core::RakeTask.new(:rspec)
  task :test => :rspec

  task :default => [ :build ]

  # Considering https://github.com/postmodern/rubygems-tasks
  desc 'Build Gem'
  task :build => [ :test ] do
    system 'gem build homebrew_automation.gemspec'
  end

  desc 'Install Gem'
  task :install => [ :build ] do
    gem = "homebrew_automation-#{HomebrewAutomation::VERSION}.gem"
    puts "Installing Gem at: #{gem}"
    system "gem install #{gem}"
  end

rescue LoadError
end
