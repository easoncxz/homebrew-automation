

module HomebrewAutomation

  # A representation of a binary build of a Homebrew package
  class Bottle

    # @param tap_url [String] Something suitable for +git clone+, e.g. +git@github.com:easoncxz/homebrew-tap.git+ or +/some/path/to/my-git-repo+
    # @param formula_name [String] As known by Homebrew
    # @param os_name [String] As known by Homebrew, e.g. +el_capitan+
    # @param filename [String] ???
    # @param content [String] ???
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

    # Takes ages to run, just like if done manually
    #
    # @raise [StandardError]
    # @return [nil]
    def build
      die unless system 'brew', 'tap', local_tap_name, @tap_url
      die unless system 'brew', 'install', '--verbose', '--build-bottle', @formula_name
      die unless system 'brew', 'bottle', '--verbose', '--json', @formula_name
    end

    # Read and analyse metadata JSON file
    # @return [Array<(String, String)>] {#minus_minus} and {#filename}
    def locate_tarball
      json_filename = Dir['*.bottle.json'].first
      unless json_filename
        build
        return locate_tarball
      end
      json = JSON.parse(File.read(json_filename))
      focus = json || die
      focus = focus[json.keys.first] || die
      focus = focus['bottle'] || die
      focus = focus['tags'] || die
      focus = focus[@os_name] || die
      @minus_minus, @filename = focus['local_filename'], focus['filename']
    end

    # The +brew bottle+ original output filename
    #
    # See https://github.com/Homebrew/brew/pull/4612 for details.
    #
    # @return [String]
    def minus_minus
      @minus_minus || locate_tarball.first
    end

    # Filename of a Bottle tarball suitable for writing into a Formula file
    #
    # @return [String]
    def filename
      @filename || locate_tarball.last
    end

    # @return [String] {#content}
    def load_tarball_from_disk
      File.rename minus_minus, filename
      @content = File.read filename
    end

    # @return [String] bytes of the tarball of this Bottle
    def content
      @content || load_tarball_from_disk
    end

    private

    # A name for the temporary tap; doesn't really matter what this is.
    def local_tap_name
      'easoncxz/local-tap'
    end

    def die
      raise StandardError.new
    end

  end

end
