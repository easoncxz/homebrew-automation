
require 'http'

module HomebrewAutomation

  # A representation of a source distribution tarball file
  class SourceDist

    # @param tag [String] a Git tag, e.g. "v0.1.1.14"
    def initialize user, repo, tag
      @user = user
      @repo = repo
      @tag = tag
    end

    attr_reader :user, :repo, :tag

    # Calculate and return the file's checksum. Lazy and memoized.
    #
    # @return [String] hex-encoded string representation of the checksum
    def sha256
      @sha256 ||= Digest::SHA256.hexdigest contents
    end

    # Fetch the file contents over HTTP. Lazy and memoized.
    #
    # @param fake [String] fake file contents (for testing)
    # @return [String] contents of the file
    def contents fake: nil
      @contents = @contents || fake ||
        begin
          resp = HTTP.follow.get url
          case resp.code
          when 200
            resp.body.to_s
          else
            puts resp
            raise StandardError.new resp.code
          end
        end
    end

    # Pure
    #
    # @return [String]
    def url
      "https://github.com/#{@user}/#{@repo}/archive/#{@tag}.tar.gz"
    end

  end

end
