
require 'homebrew_automation/effects.rb'

describe 'HomebrewAutomation::Effects' do

  describe 'State' do

    let(:state) { HomebrewAutomation::Effects::State }

    it 'implements ::pure and #run! differently from other Effects, needing an extra param and return value' do
      expect(state.pure('value').run!('state')).to eq ['value', 'state']
    end

    it 'reads the state for a ::get, and discards the value' do
      expect(state.get.run!('state')).to eq ['state', 'state']
      m =
        state.pure(3).bind do |x|
          expect(x).to eq 3
          state.get
        end
      expect(m.run! 'foo').to eq ['foo', 'foo']  # 3 is gone
    end

    it 'overwrites both the value (to nil) and the state when a `put` is run' do
      m =
        state.pure('old value').bind do |_|
          state.put('foo')
        end
      expect(m.run!('old state')).to eq [nil, 'foo']
    end

    it 'gets back what was put (put-get)' do
      m =
        state.put('new').bind do |_nil|
          expect(_nil).to be nil
          state.get
        end
      expect(m.run!('gone')).to eq ['new', 'new']
    end

    it 'is the same as pure(nil) to get then put (get-put)' do
      m =
        state.get.bind do |s|
          state.put(s)
        end
      n = state.pure(nil)
      expect(m.run!('foo')).to eq [nil, 'foo']
      expect(n.run!('foo')).to eq [nil, 'foo']
    end

    it 'threads the state through changes in the chain of actions' do
      something = Hash.new
      m =
        state.pure(something).bind do |h|
          state.get.bind do |counter|
            state.put(counter + 1).bind do
              state.get.bind do |counter|
                state.put(counter + 1).bind do
                  state.pure(h.merge(foo: 'foobar'))
                end
              end
            end
          end
        end
      expect(something).to eq Hash.new
      expect(m.run!(0)).to eq [{foo: 'foobar'}, 2]
      expect(something).to eq Hash.new
    end

    it 'can modify the state via ::modify' do
      m = state.modify do |s| s + 37 end
      expect(m.run! 10).to eq [nil, 47]
    end

    it 'can be used to implement a counting algorithm' do
      def foo
        3
      end
      expect(foo).to eq 3   # nested method definitions work

      def nest_and_nest(n)
        def sum_to(n)
          if n > 0 then n + sum_to(n - 1) else 0 end
        end
        sum_to(n)
      end
      expect(nest_and_nest(5)).to eq 15  # further nesting and recursion works

      # define our algorithm
      def count(e, xs)
        steps = xs.map do |x|
          action =
            if x == e then
              state.get.bind do |n|
                state.put(n + 1)
              end
              state.modify {|n| n + 1}
            else
              state.pure nil
            end
          expect(action).to match state
          action
        end
        overall = steps.reduce(state.pure nil) do |bundle, action|
          bundle.bind do |_nil|
            expect(_nil).to be nil
            action
          end
        end
        _nil, cnt = overall.run! 0
        expect(_nil).to be nil
        cnt
      end
      expect(count(3, [5, 10])).to be 0
      expect(count(3, [1,3,2])).to be 1
      expect(count(3, [1,2,3,3,3])).to be 3

    end

  end

end
