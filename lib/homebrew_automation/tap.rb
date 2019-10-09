
require_relative "formula.rb"
require_relative "effects/eff.rb"

module HomebrewAutomation

  # A representation of a Github repo that acts as a Homebrew Tap.
  class Tap

    Eff = HomebrewAutomation::Effects::Eff

    # See {#user}, {#repo}, {#token}.
    def initialize(user, repo, token)
      @user = user
      @repo = repo
      @token = token
      @url = "https://#{token}@github.com/#{user}/#{repo}.git"
    end

    # Github username
    #
    # @return [String]
    attr_reader :user

    # Github repo name, as appears in Github URLs
    #
    # @return [String]
    attr_reader :repo

    # Github OAuth token
    #
    # Get a token for yourself here: https://github.com/settings/tokens
    #
    # @return [String]
    attr_reader :token

    # Repo URL, as expected by Git
    #
    # @return [String]
    attr_reader :url

    # Overwrite the specified Formula file, in-place, on-disk
    #
    # Haskell-y type: <tt>(String, &Block (Formula -> Formula)) -> Formula</tt>
    #
    # If no block is passed, then this tries to find the formula file, but then
    # does nothing.
    #
    # @param formula [String] Part of the name to the file within the +Formula+
    #     directory inside the Tap repo's directory, excluding the +.rb+ suffix.
    # @yield [Formula]
    # @yieldreturn [Formula]
    # @return [Eff<Formula>] an effect that performs such change and returns the
    #   resulting Formula
    def on_formula(formula, &block)
      Eff.new do
        name = "#{formula}.rb"  # DOC
        block ||= ->(n) { n }
        Dir.chdir 'Formula' do  # DOC
          File.open name, 'r' do |old_file|
            File.open "#{name}.new", 'w' do |new_file|
              new_file.write(
                block.
                  call(Formula.parse_string(old_file.read)).
                  to_s)
            end
          end
          File.rename "#{name}.new", name
        end
      end
    end

  end

end
