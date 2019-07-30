
require_relative "formula.rb"

module HomebrewAutomation

  # A representation of a Github repo that acts as a Homebrew Tap.
  class Tap

    # Assign params to attributes.
    #
    # See {#user}, {#repo}, {#token}.
    #
    # @param keep_submodule [Boolean] Avoid deleting the cloned tap Git repo
    #   directory when possible
    def initialize(user, repo, token, keep_submodule: false)
      @repo = repo
      @url = "https://#{token}@github.com/#{user}/#{repo}.git"
      @keep_submodule = keep_submodule
    end

    # Github repo name, as appears in Github URLs
    #
    # @return [String]
    attr_reader :repo

    # Repo URL, as expected by Git
    #
    # @return [String]
    attr_reader :url

    # Github OAuth token
    #
    # Get a token for yourself here: https://github.com/settings/tokens
    #
    # @return [String]
    attr_reader :token

    # +pushd+ into a fresh clone, call the block, then clean-up.
    #
    # Haskell-y type: +forall a. &Block (() -> a) -> a+
    #
    # @yield [String] Basename of the Tap repo directory we've just chdir'd into
    # @return Whatever the block returns
    def with_git_clone(&block)
      begin
        _git_clone
        Dir.chdir @repo, &block
      ensure
        _remove_git_submodule unless @keep_submodule
      end
    end

    # Overwrite the specified Formula file, in-place, on-disk
    #
    # Haskell-y type: <tt>(String, &Block (Formula -> Formula)) -> nil</tt>
    #
    # If no block is passed, then this tries to find the formula file, but then
    # does nothing.
    #
    # @param formula [String] Part of the name to the file within the +Formula+
    #     directory inside the Tap repo's directory, excluding the +.rb+ suffix.
    # @yield [Formula]
    # @return [Formula] as returned from the block,
    #     assuming it obediantly returns a {Formula}.
    def on_formula(formula, &block)
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

    # Set Git user's name and email
    #
    # Reads environment variables:
    # - TRAVIS_GIT_USER_NAME
    # - TRAVIS_GIT_USER_EMAIL
    #
    # If either env var is not set, do nothing.
    def git_config
      name = ENV['TRAVIS_GIT_USER_NAME']
      email = ENV['TRAVIS_GIT_USER_EMAIL']
      if name && email
        system 'git', 'config', '--global', 'user.name', name
        system 'git', 'config', '--global', 'user.email', email
      end
    end

    # Just +git commit -am "$msg"+
    #
    # @param msg [String] Git commit message
    # @raise [StandardError]
    def git_commit_am(msg)
      die unless system "git", "commit", "-am", msg
    end

    # Just +git push+
    #
    # @raise [StandardError]
    def git_push
      die unless system "git", "push"
    end

    # @raise [StandardError]
    def _git_clone
      die unless system "git", "clone", @url
    end

    # @raise [StandardError]
    def _remove_git_submodule
      die unless system "rm", "-rf", @repo
    end

    private

    def die
      raise StandardError.new
    end

  end

end
