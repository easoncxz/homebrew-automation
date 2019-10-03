
module HomebrewAutomation::Effects

  # A first-class Effect abstraction
  #
  # Reify blocks of impure code into composable first-class data
  # structures. Inspired by Haskell's Monad and Scala's ZIO.
  #
  # Since Ruby is dynamically typed, I'm not going to fuss too much
  # about the specific type parametres of this type, but it'd be
  # reasonable to consider this a generic type of at least one type
  # parametre, i.e. +Eff<a>+.
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
    #
    # Consider this a generic type of at least one type parameter,
    # e.g. as +BaseEff<b>+.
    class BaseEff

      # Different parameter type here, compared to Eff.
      #
      # BaseEff<a> takes not a +Block(a -> Eff b)+ or
      # +Block(a -> BaseEff a)+ or anything like that.
      #
      # This take a plain old impure +Block(() -> a)+ that
      # expects zero arguments passed in.
      #
      # @yield [] zero params; note that this is different to Eff#initialize
      # @yieldreturn [b] a value of the type parametre to BaseEff
      def initialize(&action)
        @action = action
      end

      # @return [b]
      def run!
        @action.call
      end

    end

    # Wrap a block of plain old impure code into an Eff
    #
    # @yield [] no parametres
    # @yieldreturn [a] the type parameter of Eff
    # @return [Eff<a>]
    def initialize(&impure)
      # Notice that this involves a sneaky kind of self-reference,
      # which would lead to infinite recursion / circular dependencies if
      # left untreated: we somehow need to build an Eff-like object
      # before we're finished with defining +Eff#initialize+.
      #
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
    #
    # @param x [a] a value of any type
    # @return [Eff<a>] an Eff of that type
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
    #
    # @yield [a]
    # @yieldreturn [Eff<b>]
    # @return [Eff<b>]
    def bind(&func_eff)
      dup.bind!(&func_eff)
    end

    # Same as +#bind+, but mutate this Eff in-place
    #
    # This is suitable for when you'd be garbage-collecting
    # this Eff after calling +#bind+ anyway, and saves you
    # all that copying and GC.
    #
    # @see #bind
    #
    # @yield [a]
    # @yieldreturn [Eff<b>]
    # @return [Eff<b>]
    def bind!(&func_eff)
      # Just hold on to the Proc (i.e. func_eff) instead of calling it:
      @steps << func_eff
      self
    end

    # Execute this Eff impurely
    #
    # In other words, run this effect and return the resulting value.
    # How this Eff behaves if you decide to run it more than once is
    # up to the particular Eff subtype or particular Eff instance to
    # decide.
    #
    # @return [a] a value of the type of the type parameter to Eff
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
    #
    # @yield [a] the type that this Eff would return
    # @yieldreturn [b] some other type
    # @return [Eff<b>] an Eff of the new type
    def map(&func)
      dup.map!(&func)
    end

    # Same as +#map+, but mutates this Eff in-place
    #
    # @see #map
    #
    # @yield [a] the type that this Eff would return
    # @yieldreturn [b] some other type
    # @return [Eff<b>] an Eff of the new type
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
    # This is slightly unusual because the given Eff returns not any old value, but
    # rather specifically a +Proc+. That's why the parametre name is +eff_func+: an
    # effect of a function, i.e. an effect that returns a function.
    #
    # Like +(<**>)+ in Haskell for Applicative.
    #
    # @param eff_func [Eff<Proc (a -> b)>]
    # @return [Eff<b>]
    def apply(eff_func)
      dup.apply!(eff_func)
    end

    # Same as +#apply+, but mutates this Eff in-place
    #
    # @see #apply
    #
    # @param eff_func [Eff<Proc (a -> b)>]
    # @return [Eff<b>]
    def apply!(eff_func)
      bind! do |x|
        # Be incredibly careful here: we have NO RIGHT to mutate eff_func.
        # We must call #bind, not #bind!, on eff_func, below:
        eff_func.bind do |func|
          Eff.pure(func.call(x))
        end
      end
    end

    private

    # Somebody please teach me Ruby here...
    attr_accessor :steps

  end

end
