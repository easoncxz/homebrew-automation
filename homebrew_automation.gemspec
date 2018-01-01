
require './lib/homebrew_automation/version'

Gem::Specification.new do |s|
  s.name = 'homebrew_automation'
  s.summary = 'Automate editing of Homebrew Formula files'
  s.description = <<-HEREDOC
    If you're thinking of manipulating Homebrew Formula files
    e.g. during continuous integration, this is for you.
    See the GitHub project page for usage details.
  HEREDOC
  s.author = 'easoncxz'
  s.email = 'me@easoncxz.com'
  s.homepage = 'https://github.com/easoncxz/homebrew-automation'
  s.license = 'GPL-3.0'

  s.version = HomebrewAutomation::VERSION
  s.files = [
    'lib/homebrew_automation.rb',
    'lib/homebrew_automation/version.rb'
  ]
  s.executables += [
    'homebrew_automation.rb'
  ]

  s.required_ruby_version = '>= 2.1.8'
  s.add_development_dependency 'rspec', '~> 3.7'
  s.add_development_dependency 'rake', '~> 12.3'
  s.add_runtime_dependency 'thor', '~> 0.20'
  s.add_runtime_dependency 'http', '~> 3'
  s.add_runtime_dependency 'parser', '~> 2.4'
  s.add_runtime_dependency 'unparser', '~> 0.2'
end
