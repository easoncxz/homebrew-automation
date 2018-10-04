

module HomebrewAutomation

  class Bottle

    def initialize(
        tap_url,
        formula_name,
        os_name,
        filename: nil,
        content: nil)
      @tap_url = tap_url
      @formula_name = formula_name
      @os_name = os_name
      @filename = filename
      @minus_minus = nil  # https://github.com/Homebrew/brew/pull/4612
      @content = content
    end

    attr_reader :filename, :minus_minus

    # Takes ages to run, just like if done manually
    def build
      system 'brew', 'tap', local_tap_name, @tap_url
      system 'brew', 'install', '--verbose', '--build-bottle', @formula_name
    end

    # Read and analyse metadata
    def find_bottle_filename
      json = JSON.parse(File.read(Dir['*.json'][0]))
      focus = json[json.keys.first]['bottle']['tags'][@os_name]
      @minus_minus = focus['local_filename']
      @filename = focus['filename']
    end

    # Load data-proper
    def load_from_disk
      File.rename @minus_minus, @filename
      @content = File.read @filename
    end

    private

    def local_tap_name
      'easoncxz/local-tap'
    end

  end

end
