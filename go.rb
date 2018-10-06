
require_relative './lib/homebrew_automation.rb'

def go
  include HomebrewAutomation
  workflow = Workflow.new(
    Tap.new('easoncxz', 'homebrew-tap', ENV['EASONCXZ_GITHUB_OAUTH_TOKEN'], keep_submodule: true),
    Bintray.new('easoncxz', ENV['EASONCXZ_BINTRAY_API_KEY']))
  workflow.build_and_upload_bottle(
    SourceDist.new('easoncxz', 'hack-assembler', 'v0.1.1.17'))
  workflow
end

def pub
  include HomebrewAutomation
  workflow = Workflow.new(
    Tap.new('easoncxz', 'homebrew-tap', ENV['EASONCXZ_GITHUB_OAUTH_TOKEN'], keep_submodule: true),
    Bintray.new('easoncxz', ENV['EASONCXZ_BINTRAY_API_KEY']))
  workflow.gather_and_publish_bottles('hack-assembler', '0.1.1.17')
  workflow
end
