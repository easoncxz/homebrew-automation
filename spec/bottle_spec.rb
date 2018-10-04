
require 'homebrew_automation/bottle.rb'

describe "HomebrewAutomation::Bottle" do

  let (:json_content) { File.read "./data/sample-bottle.json" }
  let (:bottle_filename) { "hack-assembler-0.1.1.17.high_sierra.bottle.tar.gz" }
  let (:bottle_minus_minus) { "hack-assembler--0.1.1.17.high_sierra.bottle.tar.gz" }

  it 'can figure out the filenames from the one JSON file in the CWD' do
    bottle = HomebrewAutomation::Bottle.new(
      "somewhere/homebrew-tap",
      "some-package-name",
      "high_sierra"   # should match `spec/data/sample-bottle.json`
    )
    Dir.chdir 'spec/data' do
      bottle.find_bottle_filename
      expect(bottle.filename).to eq(bottle_filename)
      expect(bottle.minus_minus).to eq(bottle_minus_minus)
    end
  end

end
