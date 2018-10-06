
require_relative "formula.rb"

module HomebrewAutomation

  class Tap

    # Get a token from: https://github.com/settings/tokens
    #
    # @param keep_submodule [Boolean] When done, don't delete the tap Git repo
    def initialize(user, repo, token, keep_submodule: false)
      @repo = repo
      @url = "https://#{token}@github.com/#{user}/#{repo}.git"
      @keep_submodule = keep_submodule
    end

    attr_reader :user, :repo, :token

    # forall a. Block (() -> a) -> a
    #
    # Do something in a fresh clone, then clean-up.
    def with_git_clone(&block)
      begin
        git_clone
        Dir.chdir @repo, &block
      ensure
        remove_git_submodule unless @keep_submodule
      end
    end

    # (String, Block (Formula -> Formula)) -> nil
    #
    # Overwrite the given formula
    def on_formula(formula, &block)
      name = "#{formula}.rb"
      block ||= ->(n) { n }
      Dir.chdir 'Formula' do
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

    def git_commit_am(msg)
      die unless system "git", "commit", "-am", msg
    end

    def git_push
      die unless system "git", "push"
    end


    #private


    def git_clone
      die unless system "git", "clone", @url
    end

    def remove_git_submodule
      die unless system "rm", "-rf", @repo
    end

    def die
      raise StandardError.new
    end

  end

end
