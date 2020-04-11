
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

    class InstallFailed < StandardError
    end

    # +brew install [opts] "$fully_qualified_formula_name"+
    #
    # @param opts [Array<String>]
    # @param fully_qualified_formula_name [String]
    def self.install!(opts, fully_qualified_formula_name)
      checked('brew', 'install', *opts, fully_qualified_formula_name)
    rescue Error
      raise InstallFailed
    end

    class UninstallFailed < StandardError
    end

    # +brew uninstall [opts] "$fully_qualified_formula_name"+
    #
    # @param opts [Array<String>]
    # @param fully_qualified_formula_name [String]
    def self.uninstall!(opts, fully_qualified_formula_name)
      checked('brew', 'uninstall', *opts, fully_qualified_formula_name)
    rescue Error
      raise UninstallFailed
    end

    # +brew list [opts] "$fully_qualified_formula_name"+
    #
    # Good for checking whether a Formula is installed.
    #
    # @param opts [Array<String>]
    # @param fully_qualified_formula_name [String]
    # @return true iff the Formula is installed
    def self.list!(opts, fully_qualified_formula_name)
      system('brew', 'list', *opts, fully_qualified_formula_name)
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
        raise Error.new(args.join(' '))
      end
      result
    end

  end
end
