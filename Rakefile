
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

  # The output of the :build task
  def gemfile_path
    "homebrew_automation-#{HomebrewAutomation::VERSION}.gem"
  end

  desc 'Install Gem'
  task :install => [ :build ] do
    puts "Installing Gem at: #{gemfile_path}"
    system "gem install #{gemfile_path}"
  end

  desc 'Publish Gem to Rubygems'
  task :publish => [ :build ] do
    cred_file = '~/.gem/credential'
    File.write(
      cred_file, [
        '---',
        ":rubygems_api_key: #{ENV['RUBYGEMS_API_KEY']}",
        ""
      ].join("\n"))
    File.chmod(0600, cred_file)
    system "gem push #{gemfile_path}"
  end

rescue LoadError
end
