
require_relative '../effects/eff.rb'

module HomebrewAutomation::EffectProviders

  class Brew

    class BrewError < StandardError
    end

    Eff = HomebrewAutomation::Effects::Eff

    def self.tap(name, url)
      eff('brew', 'tap', name, url)
    end

    def self.install(opts, fully_qualified_formula_name)
      eff('brew', 'install', *opts, fully_qualified_formula_name)
    end

    def self.bottle(opts, fully_qualified_formula_name)
      eff('brew', 'bottle', *opts, fully_qualified_formula_name)
    end

    private_class_method def self.eff(*args)
      Eff.new do
        result = system(*args)
        unless result
          raise BrewError.new("Command failed: #{args}")
        end
        result
      end
    end

  end

end
