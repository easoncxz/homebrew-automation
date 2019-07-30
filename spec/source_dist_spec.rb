
require 'homebrew_automation'

require_relative './my_helpers.rb'

describe 'SourceDist' do

  let(:d_http) do
    d = double('FakeRestClient')
    expect(d).to(
      receive(:get).
      and_return(
        MyHelpers.
        instance_method(:make_response).
        bind(self).
        call(body: '你好')))
    d
  end

  it 'can calculate a sha256 checksum' do
    sdist = HomebrewAutomation::SourceDist.new('user', 'repo', 'tag', http: d_http)
    expect(sdist.sha256).to eq('670d9743542cae3ea7ebe36af56bd53648b0a1126162e78d81a32934a711302e')
  end

end
