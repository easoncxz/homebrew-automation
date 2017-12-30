
require './lib/homebrew_automation/version'

Gem::Specification.new do |s|
  s.name = 'homebrew_automation'
  s.summary = 'Automate editing of Homebrew Formula files'
  s.description = %w[ If you're thinking of manipulating Homebrew Formula files during e.g. continuous integration, this is for you ]
  s.version = HomebrewAutomation::VERSION
  s.files = [
    'lib/homebrew_automation.rb',
    'lib/homebrew_automation/version.rb'
  ]

  s.author = 'easoncxz'
  s.email = 'me@easoncxz.com'
  s.homepage = 'https://github.com/easoncxz/homebrew-automation'
  s.license = 'GPL-3.0'
  s.executables += [
    'homebrew_automation.rb'
  ]

  s.add_runtime_dependency 'thor', '~> 0.20'
  s.add_runtime_dependency 'parser', '~> 2.4'
  s.add_runtime_dependency 'unparser', '~> 0.2'
end
