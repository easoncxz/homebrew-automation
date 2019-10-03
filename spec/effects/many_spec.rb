
require 'homebrew_automation/effects.rb'

describe 'HomebrewAutomation::Effects' do

  describe 'Many' do

    let(:many) { HomebrewAutomation::Effects::Many }

    it 'interprets ::pure as a single posibility' do
      expect(many.pure(3).run!).to eq [3]
    end

    it 'provides ::from_array as a convenient constructor over ::new' do
      expect(many.new do [1,2,3] end.run!).to eq([1,2,3])
      expect(many.from_array([1,2,3]).run!).to eq([1,2,3])
    end

    it 'binds as if a flat_map would' do
      expect(many.from_array([1, 2, 3]).bind do |x|
        many.from_array [x, x, x]
      end.run!).to eq([1, 1, 1, 2, 2, 2, 3, 3, 3])
    end

    it 'enumerates in outer-major order' do
      get_number = many.from_array [1, 2, 3] # outer
      get_letter = many.from_array ['a', 'b', 'c'] # inner
      get_pair =
        get_number.bind do |n|
          get_letter.bind do |c|
            many.pure([n, c])
          end
        end
      expect(get_pair.run!).to eq(
        [
          [1, 'a'], [1, 'b'], [1, 'c'],
          [2, 'a'], [2, 'b'], [2, 'c'],
          [3, 'a'], [3, 'b'], [3, 'c']
        ]
      )
    end

    it 'collapses possibilities everywhere if there is an empty array anywhere' do
      get_number = many.from_array [1, 2, 3]
      no_choice = many.from_array []
      get_letter = many.from_array ['a', 'b']
      triplets =
        get_number.bind do |n|
          no_choice.bind do |absurd|
            get_letter.bind do |c|
              many.pure [n, absurd, c]
            end
          end
        end
      expect(triplets.run!).to eq []
    end

  end

end

