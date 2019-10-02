
module HomebrewAutomation::Effects

  class Maybe < Eff

    def self.pure(x)
      Maybe.new do
        x
      end
    end

    def self.nothing
      Maybe.new do
        nil
      end
    end

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
