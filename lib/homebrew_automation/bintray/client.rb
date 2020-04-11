
require 'json'
require 'base64'
require 'uri'
require 'rest-client'

module HomebrewAutomation
end

module HomebrewAutomation::Bintray

  # A bare-bones Bintray API client that implements only the methods needed for
  # Homebrew things.
  class Client

    # @param username [String] Bintray username; for me this was not my email address
    # @param api_key [String] Bearer-token-like key; generated in the Bintray web UI
    # @param http [RestClient.Class] The +RestClient+ class itself
    # @param base_url [String] Include the +https://+; exclude the trailing slash.
    def initialize(
        username,
        api_key,
        http: RestClient,
        base_url: "https://bintray.com/api/v1"
    )
      @username = username
      @api_key = api_key
      @base_url = base_url
      @http = http  # allow injecting mocks for testing
    end

    # <tt>POST /packages/:subject/:repo/:package/versions</tt>
    #
    # Redundant: Bintray seems to create nonexistant versions for you if you
    # just try to upload files into it.
    #
    # @param repo_name [String]
    # @param package_name [String]
    # @param version_name [String]
    # @return [RestClient::Response]
    def create_version(repo_name, package_name, version_name)
      safe_repo = URI.escape(repo_name)
      safe_pkg = URI.escape(package_name)
      @http.post(
        rel("/packages/#{safe_username}/#{safe_repo}/#{safe_pkg}/versions"),
        { name: version_name }.to_json,
        api_headers
      )
    end

    # <tt>PUT /content/:subject/:repo/:package/:version/:file_path[?publish=0/1][?override=0/1][?explode=0/1]</tt>
    #
    # Bintray seems to expect the byte sequence of the file to be written straight out into the
    # HTTP request body, optionally via <tt>Transfer-Encoding: chunked</tt>. So we pass the +content+ String
    # straight through to RestClient
    #
    # @param repo_name [String]
    # @param package_name [String]
    # @param version_name [String]
    # @param filename [String] The filename within one Bintray repository, e.g. +hack-assembler-0.1.1.17.high_sierra.bottle.tar.gz+
    # @param content [String] The bytes for the file, e.g. from a +File.read+
    # @return [RestClient::Response]
    def upload_file(repo_name, package_name, version_name, filename, content, publish: 1)
      safe_repo = URI.escape(repo_name)
      safe_pkg = URI.escape(package_name)
      safe_ver = URI.escape(version_name)
      safe_filename = URI.escape(filename)
      safe_publish = URI.escape(publish.to_s)
      @http.put(
        rel("/content/#{safe_username}/#{safe_repo}/#{safe_pkg}/#{safe_ver}/#{safe_filename}?publish=#{safe_publish}"),
        content,
        auth_headers
      )
    end

    # <tt>GET /packages/:subject/:repo/:package/versions/:version/files[?include_unpublished=0/1]</tt>
    #
    # Useful when seeing what bottles have already been built.
    #
    # @param repo_name [String]
    # @param package_name [String]
    # @param version_name [String]
    # @return [RestClient::Response]
    def get_all_files_in_version(repo_name, package_name, version_name)
      safe_repo = URI.escape(repo_name)
      safe_pkg = URI.escape(package_name)
      safe_ver = URI.escape(version_name)
      @http.get(
        rel("/packages/#{safe_username}/#{safe_repo}/#{safe_pkg}/versions/#{safe_ver}/files?include_unpublished=1"),
        auth_headers)
    end

    # Bintray username, URI-escaped.
    #
    # @return [String]
    def safe_username
      URI.escape(@username)
    end

    # Resolve a relative path into a URL using the current base_url
    #
    # @param slash_subpath [String]
    # @return [String]
    def rel(slash_subpath)
      @base_url + slash_subpath
    end

    # @return [Hash]
    def api_headers
      { "Content-Type" => "application/json" }.update auth_headers
    end

    # Implement HTTP Basich Auth, as per RFC 7617.
    #
    # Let's not bring in a library just for these two lines.
    #
    # @return [Hash]
    def auth_headers
      cred = Base64.strict_encode64("#{@username}:#{@api_key}")
      { Authorization: "Basic #{cred}" }
    end

  end

end
