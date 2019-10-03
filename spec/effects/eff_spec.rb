
require 'homebrew_automation/effects.rb'

describe 'HomebrewAutomation::Effects' do

  describe 'Eff' do
    let(:eff) { HomebrewAutomation::Effects::Eff }

    it 'can be aliased into an rspec let-binding' do
      expect(eff).not_to(be(nil))
      expect(eff.class).to(be(Class))
    end

    describe '::new' do

      it 'forms an identity with #run!' do
        expect(eff.new do 3 end.run!).to(be(3))
      end

    end

    describe '::pure' do

      it 'wraps a pure value into an Eff' do
        expect('abc').to(match(String))
        expect(eff.pure(3)).to(match(eff))
      end

      it 'forms an identity with #run!' do
        expect(eff.pure(3).run!).to(be(3))
      end

    end

    describe '#dup' do

      it 'returns a new and different Eff' do
        m = eff.pure 3
        o = m.dup
        expect(o).to(match(eff))
        expect(o).not_to(be(m))
      end

      it 'builds a new array, but keeps the old Procs' do
        m = eff.pure(3)
        o = m.dup
        marr = m.method(:steps).call
        oarr = o.method(:steps).call
        expect(o).not_to(be(m))
        expect(oarr).not_to(be(marr))
        expect(oarr).to(eq(marr))
        expect(oarr.length).to be 1
        expect(marr.length).to be 1
        mproc = marr.first
        oproc = oarr.first
        expect(mproc).to match(Proc)
        expect(oproc).to match(Proc)
        expect(mproc).to be(oproc)
      end

    end

    describe '#bind!' do

      let(:get_three) { eff.pure 3 }
      let(:monadic_incr) { Proc.new do |x| eff.pure(x + 1) end }

      it 'can bind the steps in sequence' do
        get_four = get_three.bind!(&monadic_incr)
        expect(get_four.run!).to be 4
      end

      it 'does not mutate the original Eff' do
        get_four = get_three.bind &monadic_incr
        expect(get_four).not_to be(get_three)
        expect(get_three.run!).to be 3
        expect(get_four.run!).to be 4
      end

      it 'mutates in-place if you use #bind!' do
        get_four = get_three.bind! &monadic_incr
        expect(get_four).to(be(get_three))
        expect(get_four.equal?(get_three)).to(be(true))
        expect(get_four.run!).to be 4
        expect(get_three.run!).to be 4  # mutated
      end

    end

    describe '#map and Functor behaviour' do

      let(:get_one) { eff.pure 1 }
      let(:pure_incr_lambda) { ->(x) { x + 1 } }
      let(:pure_incr_proc) { Proc.new do |x| x + 1 end }

      it 'can map over an Eff' do
        expect(eff.pure(3).map do |x| x + 1 end.run!).to(be(4))
      end

      it 'does not mutate the original Eff' do
        result_lambda = get_one.map(&pure_incr_lambda)
        result_proc = get_one.map(&pure_incr_proc)
        expect(result_lambda).not_to be(get_one)
        expect(result_proc).not_to be(get_one)
        expect(result_lambda.run!).to be 2
        expect(result_proc.run!).to be 2
        expect(get_one.run!).to be 1
      end

      it 'mutates in-place if you use #map!' do
        result_lambda = get_one.map!(&pure_incr_lambda)
        expect(result_lambda).to be(get_one)
        expect(result_lambda.run!).to be 2
        result_proc = get_one.map!(&pure_incr_proc)
        expect(result_proc).to be(get_one)
        expect(result_proc.run!).to be 3  # incremented again!
        expect(get_one.run!).to be 3
      end

    end

    describe '#apply and Applicative behaviour' do

      let(:get_three) { eff.pure(3) }
      let(:get_incr) { eff.pure(Proc.new do |x| x + 1 end) }

      it 'can apply a function returned by an Eff to the starting Eff' do
        expect(get_three.apply(get_incr).run!).to be 4
      end

      it 'does not mutate the original Eff' do
        get_four = get_three.apply(get_incr)
        expect(get_four).not_to be(get_three)
        expect(get_four.run!).to be 4
        expect(get_three.run!).to be 3
      end

      it 'mutates in-place if you use #apply!' do
        get_four = get_three.apply!(get_incr)
        expect(get_four).to be(get_three)
        expect(get_four.run!).to be 4
        expect(get_three.run!).to be 4    # mutated
      end

      it 'does NOT mutate the Eff given in the parametre even if you call #apply! and #run!' do
        get_four = get_three.apply!(get_incr)
        expect(get_four.run!).to be 4
        incr = get_incr.run!
        expect(incr).to match Proc
        expect(incr.call(5)).to be 6
      end

      it 'welcomes the use of lambdas' do
        get_incr = eff.pure(->(x) { x + 1 })
        expect(get_three.apply(get_incr).run!).to be 4
      end

    end

    describe 'how to put things together to achieve imperative code' do

      # pretend these effects are not pure
      let(:one) { eff.pure 1 }
      let(:two) { eff.pure 2 }

      it 'be nested in callback-hell style' do
        main =
          one.bind! do |x|
          two.bind! do |y|
            eff.pure(x + y)
          end
          end
        expect(main.run!).to be 3
        expect(main).to be(one)   # remember it's mutations all the way
      end

      it 'allows abuse of #map! and #run! to approach do-syntax' do
        result =
          one.map! do |x|
            y = two.run!
            x + y
          end.run!
        expect(result).to be 3
      end

      it 'would lose its purpose if you called #run! everywhere' do
        result =
          eff.pure(42).map! do
            x = one.run!
            y = two.run!
            x + y
          end.run!
        expect(result).to be 3
      end

    end

    describe 'performance of Eff' do

      let(:incr) { Proc.new do |x| eff.pure(x + 1) end }

      it 'can chain together 100k actions without any stack overflows' do
        count = 100_000
        num = eff.pure 0
        count.times do
          num = num.bind! &incr
        end
        expect(num.run!).to be(count)
      end

    end

  end

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
