
module HomebrewAutomation

  # Homebrew effects
  class Brew

    class Error < StandardError
    end

    # +brew tap "$name" "$url"+
    #
    # @param name [String]
    # @param url [String]
    def self.tap!(name, url)
      checked('brew', 'tap', name, url)
    end

    # +brew untap "$name"+
    #
    # @param name [String]
    def self.untap!(name)
      checked('brew', 'untap', name)
    end

    # +brew install [opts] "$fully_qualified_formula_name"+
    #
    # @param opts [Array<String>]
    # @param fully_qualified_formula_name [String]
    def self.install!(opts, fully_qualified_formula_name)
      checked('brew', 'install', *opts, fully_qualified_formula_name)
    end

    # +brew bottle [opts] "$fully_qualified_formula_name"+
    #
    # @param opts [Array<String>]
    # @param fully_qualified_formula_name [String]
    def self.bottle!(opts, fully_qualified_formula_name)
      checked('brew', 'bottle', *opts, fully_qualified_formula_name)
    end

    private_class_method def self.checked(*args)
      result = system(*args)
      unless result
        raise Error.new("Something went wrong in this Homebrew command: #{args.join(' ')}")
      end
      result
    end

  end
end
