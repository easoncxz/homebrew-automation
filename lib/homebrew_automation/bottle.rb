
require 'json'

require_relative './effects.rb'

module HomebrewAutomation

  # A representation of a binary build of a Homebrew package
  class Bottle

    Eff = HomebrewAutomation::Effects::Eff

    # @param tap_url [String] Something suitable for +git clone+, e.g. +git@github.com:easoncxz/homebrew-tap.git+ or +/some/path/to/my-git-repo+
    # @param formula_name [String] As known by Homebrew
    # @param os_name [String] As known by Homebrew, e.g. +el_capitan+
    # @param filename [String] ???
    # @param content [String] ???
    # @param keep_tmp [Boolean] pass +--keep-tmp+ to +brew+
    def initialize(
        tap_url,
        formula_name,
        os_name,
        tap_name: 'easoncxz/tmp-tap',
        filename: nil,
        content: nil,
        keep_tmp: false)
      @tap_url = tap_url
      @formula_name = formula_name
      @os_name = os_name
      @tap_name = tap_name
      @filename = filename
      @minus_minus = nil  # https://github.com/Homebrew/brew/pull/4612
      @content = content
      @keep_tmp = keep_tmp
    end

    # Would take ages to run, just like if done manually
    #
    # Unless you're already run +brew install --build-bottle+ on that Formula
    # on your system before already.
    #
    # @raise [StandardError]
    # @return [Eff<NilClass>]
    def build
      Eff.new do
        complain unless system 'brew', 'tap', @tap_name, @tap_url
        install_cmd =
          ['brew', 'install', '--verbose'] +
          if @keep_tmp then ['--keep-tmp'] else [] end +
          ['--build-bottle', fully_qualified_formula_name]
        complain unless system(*install_cmd)
        complain unless system(
          'brew', 'bottle', '--verbose', '--json', '--no-rebuild',
          fully_qualified_formula_name)
      end
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
      focus = json || complain
      focus = focus[fully_qualified_formula_name] || complain
      focus = focus['bottle'] || complain
      focus = focus['tags'] || complain
      focus = focus[@os_name] || complain
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

    def fully_qualified_formula_name
      @tap_name + '/' + @formula_name
    end

    def complain
      puts "HEY! Something has gone wrong and I need to complain. Stacktrace follows:"
      puts caller
    end

  end

end
