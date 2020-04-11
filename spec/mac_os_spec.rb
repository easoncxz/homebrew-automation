
require 'homebrew_automation/mac_os.rb'

describe 'MacOS' do

  let (:known_names) { [
    'yosemite',
    'el_capitan',
    'sierra',
    'high_sierra',
    'mojave',
    'catalina'
  ] }

  it 'returns one of several known strings' do
    v = HomebrewAutomation::MacOS.identify_version!
    if v
      expect(known_names).to(include(v))
    end
  end

end
