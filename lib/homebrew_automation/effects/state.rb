
module HomebrewAutomation::Effects

  # A +State<s, a>+ object represents a pure value of type +a+ with some
  # potential effect on an implicit state of type +s+
  #
  # Because a State object represents an *effect* on a state, it doesn't
  # represent any particular state, but rather a *change* of state.  I.e., a
  # function, or a block of code, that operates on a state to return a new
  # state. To interact with this implicit state (explicitly), you must use
  # +::get+, +::put+, or anything built on top of them, e.g. +::modify+.
  #
  # To +#bind+ together two State effects, is to create a bigger effect that
  # performs those two given stateful effects one after the other, while
  # passing the +a+ value from the first State to the second one, via the
  # argument to the block from which the second State is returned.
  #
  # +State<s, a>+ is isomorphic to +Block(s -> Tuple[a, s])+ in the following
  # way:
  #
  # * +::new+ builds a +State+ object from a Block;
  # * +#run!+ on a +State+ is like +#call+ on that Block.
  class State < Eff

    # Turning a Block back into a +State+-like object (with a +#run!+)
    class BaseState

      # @yieldparam state [s]
      # @yieldreturn [Tuple[a, s]]
      def initialize(&func_eff)
        @func_eff = func_eff
      end

      def run!(state)
        @func_eff.call state
      end

    end

    # Create a +State+ effect from a Block
    #
    # This is nice for pretending youre writing +State+ literals.
    #
    # Here's a +State<Integer, String>+ object that represents the value +'foo'+
    # and adds one to implicit state (of type +Integer+):
    #
    #     State.new do |s|
    #       ['foo', s + 1]
    #     end
    #
    # @yieldparam s [s]
    # @yieldreturn [Tuple[a, s]]
    # @return [State<s, a>]
    def initialize(&step)
      @steps = [->(_) { BaseState.new(&step) }]
    end

    # Just a value, with no effect on the implicit state
    #
    # @param x [a] the value
    # @return [forall t. State<t, a>]
    def self.pure(x)
      State.new do |s|
        [x, s]
      end
    end

    # Run this effects to get a value and a new state
    #
    # This passes the value along the sequence of actions that happen,
    # and threads the implicit state through the actions one by one.
    #
    # @param s [s] initial state
    # @return [Tuple[a, s]] a pair containing a value of type +a+ and
    #   the final state of type +s+
    def run!(s)
      x = nil
      @steps.each do |f|
        x, s = f.(x).run!(s)
      end
      [x, s]
    end

    # Read the implicit state as an explicit value
    #
    # This just reads the state, but makes no changes to it.
    #
    # @return [forall t. State<t, t>]
    def self.get
      if block_given?
        raise StandardError.new "Block not expected here. Did you forget to call #bind, #apply, #map, or something?"
      end
      State.new do |s|
        [s, s]
      end
    end

    # Overwrite the implicit state, leaving a nil value
    #
    # This ignores what the state previously was, and uses the argument as the
    # new state. The value is filled out to be nil.
    #
    # @param x [t]
    # @return [State<NilClass, t>]
    def self.put(x)
      if block_given?
        raise StandardError.new "Block not expected here. Did you forget to call #bind, #apply, #map, or something?"
      end
      State.new do |_|
        [nil, x]
      end
    end

    # Change the implicit state via a Block
    #
    # This is semantically no different from firsting doing +State.get+
    # and then doing +State.put+.
    #
    # @yieldparam s [s] previous state
    # @yieldreturn [s] new state you want
    # @return [State<NilClass, s>]
    def self.modify(&on_state)
      State.new do |s|
        [nil, on_state.call(s)]
      end
    end

  end

end
