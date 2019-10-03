
module HomebrewAutomation::Effects

  # A representation of a value that has many possibilities
  #
  # Binding together two +Many+ actions means to consider
  # all the possibilities (elements) by taking elements pair-wise from
  # those two actions, in self-major order.
  #
  # By "self-major order", consider this example:
  #
  #     pairs = xs.bind do |x|
  #       ys.bind do |y|
  #         Many.pure([x, y])
#         end
  #     end
  #
  # In the above, +pairs+ will be in the order of:
  #
  #     [ [x_1, y_1]
  #     , [x_1, y_2]
  #     , ...
  #     , [x_1, y_n]
  #     , [x_2, y_1]
  #     , ...
  #     , [x_2, y_n]
  #     , ...
  #     , [x_m, y_n]
  #     ]
  #
  # Consider this a generic type with one parametre,
  # i.e. +Many<a>+.

  class Many < Eff

    # Just one possibility
    #
    # @param x [a] that one possibility
    # @return [Many<a>]
    def self.pure(x)
      Many.new do
        [x]
      end
    end

    # Just the possibilities as given in the array
    #
    # @param x [Array<a>] the list of all possibilities
    # @return [Many<a>]
    def self.from_array(xs)
      Many.new do xs end
    end

    # @return [Array[a]] all the possibilities listed out as an +Array+
    def run!
      first, *rest = @steps   # Ruby creates copies, not references
      if rest.empty?
        m = first.call
        unless Eff::BaseEff === m
          raise StandardError.new(m.inspect)
        end
        m.run!
      else
        current = first.call
        rest.each do |func_eff|
          current =
            Many.from_array(
              current.run!.flat_map do |x|
                func_eff.call(x).run!
              end
            )
        end
        current.run!
      end
    end

  end

end
