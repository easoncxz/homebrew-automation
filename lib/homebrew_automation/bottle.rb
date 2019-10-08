
require 'json'

require_relative './effects.rb'
require_relative './effect_providers.rb'

module HomebrewAutomation

  # Metadata for building a Bottle for a Homebrew package
  class Bottle

    Eff = HomebrewAutomation::Effects::Eff

    EP = HomebrewAutomation::EffectProviders

    class BottleError < StandardError
    end

    # @param tap_url [String] Something suitable for +git clone+, e.g. +git@github.com:easoncxz/homebrew-tap.git+ or +/some/path/to/my-git-repo+
    # @param formula_name [String] As known by Homebrew
    # @param os_name [String] As known by Homebrew, e.g. +el_capitan+
    # @param tap_name [String] For use with +brew tap+
    # @param keep_tmp [Boolean] pass +--keep-tmp+ to +brew+
    def initialize(
        tap_url,
        formula_name,
        os_name,
        tap_name: 'easoncxz/tmp-tap',
        keep_tmp: false,
        brew: EP::Brew,
        bottle_finder: Bottle,
        file: EP::File)
      @tap_url = tap_url
      @formula_name = formula_name
      @os_name = os_name
      @tap_name = tap_name
      @keep_tmp = keep_tmp
      @brew = brew
      @bottle_finder = bottle_finder
      @file = file
    end

    # Build the bottle and get a file suitable for Bintray upload
    #
    # Unless you've already run +brew install --build-bottle+ on that Formula
    # on your system before, the returned effect would take ages to run (looking
    # at about 30-60 minutes).
    #
    # @return [Eff<Tuple<String, String>, error: BottleError>] +[filename, contents]+
    def build
      call_brew.bind! do
        @bottle_finder.read_json
      end.map! do |json_str|
        parse_for_tarball_path(json_str)
      end.bind! do |(minus_minus, filename)|
        @file.read(minus_minus).bind! do |contents|
          Eff.pure([filename, contents])
        end
      end
    end

    private

    # @return [Eff<NilClass>]
    def call_brew
      @brew.tap(@tap_name, @tap_url).bind! do
        @brew.install(
          %w[--verbose --build-bottle] + if @keep_tmp then %w[--keep-tmp] else [] end,
          fully_qualified_formula_name)
      end.bind! do
        @brew.bottle(
          %w[--verbose --json --no-rebuild],
          fully_qualified_formula_name)
      end
    end

    # pure-ish; raises exception
    #
    # @return [Tuple<String, String>] +[minus_minus, filename]+
    def parse_for_tarball_path(json_str)
      begin
        focus = JSON.parse(json_str)
        [fully_qualified_formula_name, 'bottle', 'tags', @os_name].each do |key|
          focus = focus[key]
          if focus.nil?
            raise BottleError.new "unexpected JSON structure, couldn't find key: #{key}"
          end
        end
        # https://github.com/Homebrew/brew/pull/4612
        minus_minus, filename = focus['local_filename'], focus['filename']
        if minus_minus.nil? || filename.nil?
          raise BottleError.new "unexpected JSON structure, couldn't find both `local_filename` and `filename` keys: #{minus_minus.inspect}, #{filename.inspect}"
        end
        [minus_minus, filename]
      rescue JSON::ParserError => e
        raise BottleError.new "error parsing JSON: #{e}"
      end
    end

    def fully_qualified_formula_name
      @tap_name + '/' + @formula_name
    end

    # @return [Eff<String>]
    def self.read_json
      Eff.new do
        json_filename = Dir['*.bottle.json'].first
        File.read(json_filename)
      end
    end

  end

end
