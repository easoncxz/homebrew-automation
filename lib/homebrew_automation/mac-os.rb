
module HomebrewAutomation

  class MacOS

    # () -> String
    #
    # Returns a representation of the macOS version name in a format recognised by Homebrew,
    # in particular the Formula/Bottle DSL.
    def self.identify_version
      version = `sw_vers -productVersion`
      mac_to_homebrew.
        select { |pattern, _| pattern === version }.
        map { |_, description| description }.
        first
    end

    def self.mac_to_homebrew
      {
        /^10.10/ => 'yosemite',
        /^10.11/ => 'el_capitan',
        /^10.12/ => 'sierra',
        /^10.13/ => 'high_sierra'
      }
    end

  end

end
