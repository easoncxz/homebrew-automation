
require 'homebrew_automation/bottle.rb'
require 'homebrew_automation/effects.rb'
require 'homebrew_automation/effect_providers/file.rb'

describe "HomebrewAutomation::Bottle" do

  let(:bottle_filename) { "hack-assembler-0.1.1.28.high_sierra.bottle.tar.gz" }
  let(:bottle_contents) do
    File.read("hack-assembler--0.1.1.28.high_sierra.bottle.tar.gz" )
  end
  let(:bottle_json_filename) { "hack-assembler--0.1.1.28.high_sierra.bottle.json" }

  let(:fake_brew) { double }

  Eff = HomebrewAutomation::Effects::Eff
  EP = HomebrewAutomation::EffectProviders

  it 'can figure out the filenames from the one JSON file in the CWD' do
    bottle = HomebrewAutomation::Bottle.new(
      "somewhere/homebrew-tap",
      "hack-assembler",               # should match bottle JSON
      "high_sierra",                  # should match bottle JSON
      tap_name: 'easoncxz/tap',       # should match bottle JSON
      brew: fake_brew
    )

    [:tap, :install, :bottle].each do |cmd|
      expect(fake_brew).to receive(cmd).and_return(Eff.pure(nil)).ordered
    end

    Dir.chdir 'spec/data/bottle' do
      expect(EP::File.read(bottle_json_filename).run!).to(
        eq(File.read bottle_json_filename))
      (filename, contents) = bottle.build.run!
      expect(filename).to eq(bottle_filename)
      expect(contents).to match String
      expect(bottle_contents).to match String
      expect(contents).to eq(bottle_contents)
    end
  end

end
