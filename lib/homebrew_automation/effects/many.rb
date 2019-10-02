
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

  end

end
