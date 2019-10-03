
module HomebrewAutomation::Effects

  # Deal with nils only on the outside
  #
  # Keep chaining operations as if there were no nils,
  # this effect short-circuits out all effects after the first nil.
  #
  # Consider this a generic type with one type parametre,
  # i.e. +Maybe<a>+.
  class Maybe < Eff

    # Wrap an ordinary value into a chainable +Maybe+
    #
    # @param x [a]
    # @return [Maybe<a>]
    def self.just(x)
      self.pure(x)
    end

    # Same as +#just+
    #
    # @param x [a]
    # @return [Maybe<a>]
    def self.pure(x)
      Maybe.new do
        x
      end
    end

    # Wrap a nil into a chainable +Maybe+
    #
    # This causes the rest of the chain to be forfeited.
    #
    # @return [forall b. Maybe<b>]
    def self.nothing
      Maybe.new do
        nil
      end
    end

    # Execute actions chained up, stopping and failing at the first nil
    #
    # @return [a | NilClass] the value returned by the last and final
    #   link in the chain of actions
    def run!
      current = nil
      @steps.each do |func_eff|
        eff = func_eff.call(current)
        current = eff.run!
        return nil if current.nil?
      end
      current
    end

  end

end
