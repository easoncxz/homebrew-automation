
require_relative './mac_os.rb'
require_relative './formula.rb'

module HomebrewAutomation

  # See what Bottles have already been built and uploaded to Bintray
  class BottleGatherer

    # @param json [Array<Hash>] JSON from a +RestClient::Response+ containing the list of files from Bintray
    def initialize(json)
      @json = json
      @bottles = nil
    end

    # The bottles gathered.
    #
    # @return [Hash<String, String>] with keys being OS names (in Homebrew-form) and values being SHA256 checksums
    def bottles
      return @bottles if @bottles
      pairs = @json.map do |f|
        os = _parse_for_os(f['name'])
        checksum = f['sha256']
        [os, checksum]
      end
      @bottles = Hash[pairs]
    end

    # Put all bottles gathered here into the given formula, then return the result
    #
    # @param formula [HomebrewAutomation::Formula]
    # @return [HomebrewAutomation::Formula]
    def put_bottles_into(formula)
      bottles.reduce(formula) do |formula, (os, checksum)|
        formula.put_bottle(os, checksum)
      end
    end

    # @param bottle_filename [String] filename
    # @return [String] OS name
    def _parse_for_os(bottle_filename)
      File.extname(
        File.basename(bottle_filename, '.bottle.tar.gz')).
      sub(/^\./, '')
    end

  end

end
