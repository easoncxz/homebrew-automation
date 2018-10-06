
require 'homebrew_automation/bottle_gatherer.rb'

describe "BottleGatherer" do

  let (:response_filepath) { "spec/data/sample-files-list.json" }
  let (:response_json) { JSON.parse(File.read response_filepath) }

  describe "from the sample Bintray response" do

    let (:gatherer) { HomebrewAutomation::BottleGatherer.new(response_json) }

    it 'can figure out OS name from a bottle filename' do
      bottle_filename = "hack-assembler-0.1.1.17.high_sierra.bottle.tar.gz"
      expect(gatherer.parse_for_os(bottle_filename)).to eq('high_sierra')
    end

    it 'finds one bottle' do
      expect(gatherer.bottles).to eq({
        'high_sierra' => "d985f1ec04a7a2c1cbf493362045f436e626e82e3e00b63e279504089c0ac2fd"
      })
    end

  end

end

