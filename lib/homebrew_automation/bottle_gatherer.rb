
require_relative './mac-os.rb'

module HomebrewAutomation

  # Some functions for figuring out, from files on Bintray, what values to use in bottle DSL.
  class BottleGatherer

    # @param json [Hash]  List of files from Bintray
    def initialize(json)
      @json = json
    end

    # () -> Hash String String
    #
    # Returns a hash with keys being OS names (in Homebrew-form) and values being SHA256 checksums
    def bottles
      pairs = @json.map do |f|
        os = parse_for_os(f['name'])
        checksum = f['sha256']
        [os, checksum]
      end
      Hash[pairs]
    end

    #private

    # String -> String
    #
    # filename -> OS name
    def parse_for_os(bottle_filename)
      File.extname(
        File.basename(bottle_filename, '.bottle.tar.gz')).
      sub(/^\./, '')
    end

  end

end
