
require 'rest-client'

module HomebrewAutomation

  # A representation of a source distribution tarball file
  class SourceDist

    class Error < StandardError
    end

    # Assign args to attributes {#user}, {#repo}, {#tag}
    def initialize user, repo, tag, http: RestClient
      @user = user
      @repo = repo
      @tag = tag
      @http = http
    end

    # Github username, as appears in Github URLs
    #
    # @return [String]
    attr_reader :user

    # Github repo name, as appears in Github URLs
    #
    # @return [String]
    attr_reader :repo

    # Git tag name, as usable in +git+ commands
    #
    # @return [String]
    attr_reader :tag

    # Calculate and return the file's checksum.
    #
    # Lazy and memoized. Download the file if we haven't already.
    #
    # @return [String] hex-encoded string representation of the checksum
    def sha256
      @sha256 ||= Digest::SHA256.hexdigest contents
    end

    class SdistDoesNotExist < StandardError
    end

    # Download and return the file contents.
    #
    # Lazy and memoized.
    #
    # @return [String] contents of the file
    def contents
      @contents = @contents ||
        begin
          resp = @http.get url
          case resp.code
          when 200
            resp.body.to_s
          else
            raise Error.new "Other error: HTTP #{resp.code}"
          end
        rescue RestClient::NotFound
          raise SdistDoesNotExist.new
        end
    end

    # The URL to the source tarball Github generates for tagged commits
    #
    # @return [String]
    def url
      "https://github.com/#{@user}/#{@repo}/archive/#{@tag}.tar.gz"
    end

  end

end
