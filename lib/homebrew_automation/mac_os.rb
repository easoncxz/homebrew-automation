
module HomebrewAutomation

  # Inspect version of the macOS we're running on
  class MacOS

    # Identify the version of the macOS this is run on
    #
    # Return a macOS version name in a convention recognised by Homebrew, in
    # particular by the Formula/Bottle DSL.
    #
    # @return [Eff<String | NilClass>]
    def self.identify_version
      Eff.new do
        begin
          `sw_vers -productVersion`
        rescue Errno::ENOENT    # if we're not on a Mac
          nil
        end
      end.bind! do |version|
        mac_to_homebrew.
          select { |pattern, _| pattern === version }.
          map { |_, description| description }.
          first
      end
    end

    # Lookup table of numeric version patterns to Homebrew-recognised strings
    #
    # @return [Hash<Regexp, String>]
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
