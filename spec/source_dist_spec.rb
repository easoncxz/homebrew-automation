
require 'homebrew_automation'

describe 'SourceDist' do

  it 'can calculate a sha256 checksum' do
    sdist = HomebrewAutomation::SourceDist.new 'user', 'repo', 'tag'
    sdist.contents fake: '你好'  # inject fake file contents
    expect(sdist.sha256).to eq('670d9743542cae3ea7ebe36af56bd53648b0a1126162e78d81a32934a711302e')
  end

end
