
module HomebrewAutomation

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

    # Wrap a block of impure code into an Eff
    def initialize(&b)
      @actions = [b]
    end

    # Create an Eff that would just return the given pure value
    def self.pure(x)
      Eff.new do
        x
      end
    end

    # Copy one-level-deeper, to make everything safe to
    # pass around. References to Proc objects are shared,
    # since Procs seem to be immutable.
    def initialize_copy(orig)
      @actions = orig.method(:actions).call.dup
    end

    # Thread together this Eff and the given block
    #
    # Create a new Eff that would be the combination of
    # passing this Eff's output into the given block of code,
    # and returning what the given block would return
    def bind(&b)
      m = dup
      m.method(:actions).call << b
      m
    end

    # Same as +#bind+, but mutate this Eff in-place
    #
    # This is suitable for when you'd be garbage-collecting
    # this Eff after calling +#bind+ anyway, and saves you
    # all that copying and GC.
    def bind!(&b)
      @actions << b
    end

    # Execute this Eff impurely
    def run!
      result = nil
      @actions.each do |b|
        begin
          result = b.call(result)
        end
      end
      result
    end

    private

    # Somebody please teach me Ruby here...
    attr_accessor :actions

  end

end
