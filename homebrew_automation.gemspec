
Gem::Specification.new do |s|
  s.name = 'homebrew_automation'
  s.summary = 'Automate editing of Homebrew Formula files'
  s.description = %w[ If you're thinking of manipulating Homebrew Formula files during e.g. continuous integration, this is for you ]
  s.version = '0.0.1'
  s.files = [ 'lib/homebrew_automation.rb' ]

  s.author = 'easoncxz'
  s.email = 'me@easoncxz.com'
  s.homepage = 'https://github.com/easoncxz/homebrew-automation'
  s.license = 'GPL-v3.0'
  s.executables += [
    'update_formula_bottle.rb',
    'update_formula_sdist.rb'
  ]

  s.add_runtime_dependency 'parser', '~> 2.4'
  s.add_runtime_dependency 'unparser', '~> 0.2'
end
