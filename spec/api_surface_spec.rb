
require 'homebrew_automation'

describe 'The API of HomebrewAutomation' do

  describe 'The Formula class' do

    it 'has one own public class methods' do
      expect(HomebrewAutomation::Formula.methods(false).sort).
        to eq([:parse_string])
    end

    it 'only has three own public instance methods' do
      expect(HomebrewAutomation::Formula.public_instance_methods(false).sort).
        to eq([:==, :hash, :eql?, :to_s, :update_field, :put_bottle].sort)
    end

  end
end
