
module HomebrewAutomation::Effects

  # An isomorphic type to +Block(s -> Tuple[a, s])+
  #
  # Consider this a generic type with two type parameters, i.e. +State<s, a>+.
  class State < Eff

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

    # Different format from other Eff subclasses.
    #
    # @yieldparam s [s]
    # @yieldreturn [Tuple[a, s]]
    # @return [State<a>]
    def initialize(&step)
      @steps = [->(_) { BaseState.new(&step) }]
    end

    def self.pure(x)
      State.new do |s|
        [x, s]
      end
    end

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

    def self.get
      State.new do |s|
        [s, s]
      end
    end

    def self.put(x)
      State.new do |_|
        [nil, x]
      end
    end

  end

end
