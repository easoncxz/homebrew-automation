
module HomebrewAutomation

  # Homebrew effects
  class Brew

    class Error < StandardError
    end

    def self.tap!(name, url)
      checked('brew', 'tap', name, url)
    end

    def self.install!(opts, fully_qualified_formula_name)
      checked('brew', 'install', *opts, fully_qualified_formula_name)
    end

    def self.bottle!(opts, fully_qualified_formula_name)
      checked('brew', 'bottle', *opts, fully_qualified_formula_name)
    end

    private_class_method def self.checked(*args)
      result = system(*args)
      unless result
        raise BrewError.new("Command failed: #{args}")
      end
      result
    end

  end
end
