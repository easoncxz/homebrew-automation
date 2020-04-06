
require 'homebrew_automation/bottle.rb'

describe "HomebrewAutomation::Bottle" do

  prefix = 'spec/data/bottle/'

  let(:bottle_filename) { "hack-assembler-0.1.1.28.high_sierra.bottle.tar.gz" }
  let(:bottle_json) do
    File.read(prefix + "hack-assembler--0.1.1.28.high_sierra.bottle.json")
  end
  let(:bottle_tarball) do
    File.read(prefix + "hack-assembler--0.1.1.28.high_sierra.bottle.tar.gz" )
  end

  let(:fake_brew) { double }
  let(:fake_bottle_finder) { double }
  let(:bottle) {
    HomebrewAutomation::Bottle.new(
      'easoncxz/tap',                 # should match bottle JSON
      "./somewhere/homebrew-tap",
      "hack-assembler",               # should match bottle JSON
      "high_sierra",                  # should match bottle JSON
      brew: fake_brew,
      bottle_finder: fake_bottle_finder
    )
  }

  it 'can figure out the filenames from the one JSON file in the CWD' do
    expect(fake_brew).to receive(:tap!).ordered
    expect(fake_brew).to receive(:list!).ordered.and_return(false)
    [:install!, :bottle!, :untap!].each do |cmd|
      expect(fake_brew).to receive(cmd).ordered
    end

    expect(fake_bottle_finder).to receive(:read_json!).
      and_return(bottle_json)
    expect(fake_bottle_finder).to receive(:read_tarball!).
      and_return(bottle_tarball)

    bottle.build! do |filename, contents|
      expect(filename).to eq(bottle_filename)
      expect(contents).to eq(bottle_tarball)
    end
  end

  it 'uninstalls the Formula first if it is installed' do
    expect(fake_brew).to receive(:tap!).ordered
    # pretend Formula was installed:
    expect(fake_brew).to receive(:list!).ordered.and_return(true)
    [:uninstall!, :install!, :bottle!, :untap!].each do |cmd|
      expect(fake_brew).to receive(cmd).ordered
    end

    expect(fake_bottle_finder).to receive(:read_json!).
      and_return(bottle_json)
    expect(fake_bottle_finder).to receive(:read_tarball!).
      and_return(bottle_tarball)

    bottle.build! do |filename, contents|
      expect(filename).to eq(bottle_filename)
      expect(contents).to eq(bottle_tarball)
    end
  end

end
