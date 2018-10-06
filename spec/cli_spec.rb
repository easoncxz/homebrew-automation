
describe "the CLI" do

  it 'can be launched' do
    expect(system 'bin/homebrew_automation.rb', out: '/dev/null').to be(true)
  end

end
