
require_relative './mac-os.rb'
require_relative './formula.rb'

module HomebrewAutomation

  # Some functions for figuring out, from files on Bintray, what values to use in bottle DSL.
  class BottleGatherer

    # @param json [Hash]  List of files from Bintray
    def initialize(json)
      @json = json
      @bottles = nil
    end

    # () -> Hash String String
    #
    # Returns a hash with keys being OS names (in Homebrew-form) and values being SHA256 checksums
    def bottles
      return @bottles if @bottles
      pairs = @json.map do |f|
        os = parse_for_os(f['name'])
        checksum = f['sha256']
        [os, checksum]
      end
      @bottles = Hash[pairs]
    end

    # Formula -> Formula
    #
    # Put all bottles gathered here into the given formula, then return the result
    def put_bottles_into(formula)
      bottles.reduce(formula) do |formula, (os, checksum)|
        formula.put_bottle(os, checksum)
      end
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
