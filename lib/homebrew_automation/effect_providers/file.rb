
require_relative '../effects/eff.rb'

module HomebrewAutomation::EffectProviders

  Eff = HomebrewAutomation::Effects::Eff

  class File

    def self.read(path)
      Eff.new do
        ::File.read path
      end
    end

  end

end
