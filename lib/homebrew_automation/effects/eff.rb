
module HomebrewAutomation::Effects

  # A first-class Effect abstraction
  #
  # Reify blocks of impure code into composable
  # first-class data structures. Inspired by Haskell and Scala's
  # ZIO. This class should be well-suited to be factored out into
  # its own little library.
  #
  # Error handling::
  #   Exceptions would just bubble through the usual way,
  #   forfeiting unexecuted actions in the Effect.
  #
  # Concurrency and parallelism etc.::
  #   not considered, but should be safe and easy to add
  #   as and when needed.
  class Eff

    # A kind of base-case I somehow needed internally, to break some
    # infinite recursion kind of scenario.
    #
    # All we need is a +#run+ in this class, to slot up to
    # what a usual Eff wants.
    class BaseEff

      # Different parameter type here, compared to Eff.
      #
      # BaseEff<a> takes not a +Block(a -> Eff b)+ or
      # +Block(a -> BaseEff a)+ or anything like that.
      #
      # This take a plain old impure +Block(Any -> a)+.
      def initialize(&action)
        @action = action
      end

      def run!
        @action.call
      end

    end

    # Wrap a block of plain old impure code into an Eff
    #
    # Notice that this involves a sneaky kind of self-reference,
    # which would lead to infinite recursion / circular dependencies if
    # left untreated: we somehow need to build an Eff-like object
    # before we're finished with defining +Eff#initialize+.
    def initialize(&impure)
      # Each step looks like this:
      #
      #           +---+
      #     a --> |   | --> b
      #           | ? |
      #           |   | --> something else
      #           +---+
      #
      # Specifically, they are functions (in the form of Ruby
      # blocks/Procs) which when called, would return an Eff,
      # or in this case, an Eff-like BaseEff object.
      @steps = [Proc.new do BaseEff.new(&impure) end]
    end

    # Copy one-level-deeper, to make everything safe to
    # pass around. References to Proc objects are shared,
    # since Procs seem to be immutable.
    def initialize_copy(orig)
      @steps = orig.method(:steps).call.dup
    end


    # Create an Eff that would just return the given pure value
    #
    # Like +pure+ in Haskell for Applicative.
    def self.pure(x)
      Eff.new do
        x
      end
    end

    # Bind a block that returns an Eff, over the result of this Eff
    #
    # That is, to pass this Eff's output into the given block of code,
    # and take the Eff returned by the given block as the overall Eff.
    #
    # Like +(>>=)+ in Haskell for Monad.
    def bind(&func_eff)
      dup.bind!(&func_eff)
    end

    # Same as +#bind+, but mutate this Eff in-place
    #
    # This is suitable for when you'd be garbage-collecting
    # this Eff after calling +#bind+ anyway, and saves you
    # all that copying and GC.
    def bind!(&func_eff)
      @steps << func_eff
      self
    end

    # Execute this Eff impurely
    def run!
      result = nil
      @steps.each do |func_eff|
        eff = func_eff.call(result)
        result = eff.run!
      end
      result
    end

    # Map a block of code over the result of this Eff
    #
    # That is, to transform the output of this Eff via a pure function
    # in the form of a Ruby block.
    #
    # Like +(<&>)+ in Haskell for Functor.
    def map(&func)
      dup.map!(&func)
    end

    # Same as +#map+, but mutates this Eff in-place
    def map!(&func)
      bind! do |x|
        Eff.pure(func.call(x))
      end
    end

    # Apply the function resulting from the given Eff over the result of this Eff
    #
    # That is, to first run this Eff, then run the given Eff to get a pure function,
    # and finally pass the previous result (from this Eff) into the function obtained
    # from the given Eff.
    #
    # Like +(<**>)+ in Haskell for Applicative.
    def apply(eff_func)
      dup.apply!(eff_func)
    end

    # Like +#apply+, but mutates this Eff in-place
    def apply!(eff_func)
      bind! do |x|
        func = eff_func.run!
        Eff.pure(func.call(x))
      end
    end

    private

    # Somebody please teach me Ruby here...
    attr_accessor :steps

  end

end
