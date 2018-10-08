
require './lib/homebrew_automation/version'

Gem::Specification.new do |s|
  s.name = 'homebrew_automation'
  s.summary = 'Build bottles and update Formulae'
  s.description = '== Build Bottles and update Formulae' + <<-HEREDOC

    This is a Ruby library, with a small CLI, for:

    - Editing Formula files programmatically;
    - Building Bottles for an existing Formula;
    - Uploading Bottles tarballs to Bintray;
    - Searching for and gathering Bottle tarballs from Bintray; and
    - Updating Formula files to refer to new Bottles, by committing to
      the Tap Git repo.

    I'll avoid repeating myself too much, so for more info, please look at the
    README in the Github repo.
  HEREDOC
  s.author = 'easoncxz'
  s.email = 'me@easoncxz.com'
  s.homepage = 'https://github.com/easoncxz/homebrew-automation'
  s.license = 'GPL-3.0'

  s.version = HomebrewAutomation::VERSION
  s.files = Dir['lib/**/*.rb']
  s.executables += [
    'homebrew_automation.rb'
  ]

  s.required_ruby_version = '>= 2.1.8'
  s.add_development_dependency 'rspec', '~> 3.7'
  s.add_development_dependency 'rake', '~> 12.3'
  s.add_development_dependency 'pry-byebug', '~> 3.6'
  s.add_runtime_dependency 'thor', '~> 0.20'
  s.add_runtime_dependency 'http', '~> 3'
  s.add_runtime_dependency 'parser', '~> 2.4'
  s.add_runtime_dependency 'unparser', '~> 0.2'
  s.add_runtime_dependency 'rest-client', '~> 2.0'
end
