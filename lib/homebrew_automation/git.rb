
require 'fileutils'

module HomebrewAutomation

  # Git effects
  class Git

    class Error < StandardError
    end

    class << self

      # Set Git user's name and email
      #
      # Reads environment variables:
      # - TRAVIS_GIT_USER_NAME
      # - TRAVIS_GIT_USER_EMAIL
      #
      # If either env var is not set, do nothing.
      #
      # @return [NilClass]
      def config!
        name = ENV['TRAVIS_GIT_USER_NAME']
        email = ENV['TRAVIS_GIT_USER_EMAIL']
        if name && email
          raise_unless 'git', 'config', '--global', 'user.name', name
          raise_unless 'git', 'config', '--global', 'user.email', email
        end
      end

      # Just +git clone+ the given URL
      #
      # @param url [String] git-friendly URL; could be filesystem path
      # @param dir [String] optionally specify target dir name
      # @return [NilClass]
      def clone!(url, dir: nil)
        if dir
          raise_unless 'git', 'clone', url, dir
        else
          raise_unless 'git', 'clone', url
        end
      end

      # Like {#clone!} , but allows you to do something inside
      # the newly cloned directory, pushd-style.
      #
      # @see clone!
      # @param url [String]
      # @param dir [String]
      # @param keep_dir [Boolean]
      # @yieldparam dir [String] name of freshly cloned dir
      # @yieldreturn [a] anything
      # @return [a]
      def with_clone!(url, dir, keep_dir: false, &block)
        begin
          clone! url, dir: dir
          if block
            Dir.chdir dir, &block
          else
            puts "Strange, you're calling Git#with_clone! without a block."
          end
          nil
        ensure
          FileUtils.remove_dir(dir) unless keep_dir
        end
      end

      # +git commit --allow-empty -am "$msg"+
      #
      # @param msg [String] Git commit message
      # @return [NilClass]
      def commit_am!(msg)
        raise_unless 'git', 'commit', '--allow-empty', '-am', msg
      end

      # Just +git push+
      #
      # @return [NilClass]
      def push!
        raise_unless 'git', 'push'
      end

      private

      def raise_unless(*args)
        begin
          result = system(*args)
          unless result
            raise Error, "Git command failed: #{args}"
          end
          result
        end
      end

      # Impure
      def complain_unless(*args)
        result = system(*args)
        unless result
          puts "Git command errored: #{args}"
          puts caller
        end
        result
      end

      def silently(*args)
        system(*args)
      end

    end

  end

end
