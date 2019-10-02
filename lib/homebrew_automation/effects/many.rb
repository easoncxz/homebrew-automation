
module HomebrewAutomation::Effects

  class Many < Eff

    def self.pure(x)
      Many.new do
        [x]
      end
    end

    def self.from_array(xs)
      Many.new do xs end
    end

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
