
require 'homebrew_automation/effects.rb'

describe 'HomebrewAutomation::Effects' do

  describe 'Maybe' do

    let(:maybe) { HomebrewAutomation::Effects::Maybe }

    it 'can be created with a value' do
      expect(maybe.pure(3)).to match maybe
    end

    it 'can return the value you gave it' do
      expect(maybe.pure(3).run!).to be 3
    end

    it 'can be created empty' do
      expect(maybe.nothing).to match maybe
      expect(nil).not_to match maybe
    end

    it 'can be chained together via #bind' do
      n =
        maybe.pure(3).bind do |x|
          maybe.pure(4).bind do |y|
            maybe.pure(x + y)
          end
        end
      expect(n.run!).to be 7
    end

    it 'short-circuits out as soon as one link in the chain is a nil' do
      n =
        maybe.pure(3).bind do |x|
          maybe.nothing.bind do |y|
            maybe.pure(4).bind do |z|
              maybe.pure 42
            end
          end
        end
      expect(n.run!).to be nil
    end

    it "doesn't ever touch any blocks that come after the nothing block" do
      d = 0
      n =
        maybe.new do
          d += 1    # side effect, which we can observe
          3
        end.bind do |x|
          maybe.nothing.bind do |y|
            d += 1  # side effect, which doesn't get run
            let_us_put_in_a_name_error_here_cos_why_not   # obviously this line is never run
            maybe.pure(x + y)
          end
        end
      expect(d).to be 0
      expect(n.run!).to be nil
      expect(d).to be 1   # not 2
    end

    describe 'its lawfulness' do

      let(:incr) { ->(n) { n + 1 } }
      let(:get_incr) do maybe.pure(->(n) { n + 1 }) end
      let(:get_three) { maybe.pure 3 }

      it 'supports #map' do
        expect(get_three.map(&incr).run!).to be 4
        expect(maybe.nothing.map(&incr).run!).to be nil
      end

      it 'supports #apply' do
        expect(get_three.apply(get_incr).run!).to be 4
        expect(maybe.nothing.apply(get_incr).run!).to be nil
      end

      it 'mutates on #map!' do
        get_four = get_three.map!(&incr)
        expect(get_four.run!).to be 4
        expect(get_three.run!).to be 4
      end

      it 'mutates on #apply!' do
        get_four = get_three.apply!(get_incr)
        expect(get_four.run!).to be 4
        expect(get_three.run!).to be 4
      end

      it "doesn't mutate the argument to #apply!" do
        get_four = get_three.apply!(get_incr)
        expect(get_four.run!).to be 4
        new_incr = get_incr.run!
        expect(new_incr).to match Proc
        expect(new_incr.call(56)).to be 57
      end

      it 'mutates on #bind!' do
        get_four = get_three.bind! do |n| maybe.pure(n + 1) end
        expect(get_four).to be get_three
        expect(get_four.run!).to be 4
        expect(get_three.run!).to be 4  # mutated
      end

    end

  end

end
