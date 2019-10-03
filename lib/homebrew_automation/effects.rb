
module HomebrewAutomation

  # Reified effects, also Monads
  #
  # Stuff in this module is kind of written for fun of implementing it, but
  # also with a goal to dramatically simplify testing by interpreting the
  # effects in a program in a fake world.
  #
  # API and implementation design goals:
  #
  # * Don't blow the call stack, even if you +Eff#bind+ together lots and lots
  #   of Eff objects. (If data structures get nested, or the implementation
  #   is kinda slow, that's fine.)
  # * Linear runtime and memory overhead over plain side-effecting Ruby.
  # * Minimise the use of Ruby magic, in particular +method_missing+.
  # * Not address concerns about async, concurrency, parallelism etc. just yet.
  #
  # Start by exploring {Eff}.
  module Effects
  end

end

require_relative 'effects/eff.rb'
require_relative 'effects/maybe.rb'
require_relative 'effects/many.rb'
require_relative 'effects/state.rb'
