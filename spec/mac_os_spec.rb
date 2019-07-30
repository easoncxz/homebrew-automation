
require 'homebrew_automation/mac_os.rb'

describe 'MacOS' do

  let (:known_names) { ['yosemite', 'el_capitan', 'sierra', 'high_sierra'] }

  it 'returns one of several known strings' do
    expect(known_names).to(include(HomebrewAutomation::MacOS.identify_version))
  end

end
