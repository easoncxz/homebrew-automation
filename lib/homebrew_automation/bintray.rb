
require 'json'
require 'base64'
require 'uri'
require 'rest-client'

module HomebrewAutomation

  class Bintray

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

    # POST /packages/:subject/:repo/:package/versions
    #
    # Redundant: Bintray seems to create nonexistant versions for you if you
    # just try to upload files into it.
    def create_version(repo_name, package_name, version_name)
      safe_repo = URI.escape(repo_name)
      safe_pkg = URI.escape(package_name)
      @http.post(
        rel("/packages/#{safe_username}/#{safe_repo}/#{safe_pkg}/versions"),
        { name: version_name }.to_json,
        api_headers
      )
    end

    # PUT /content/:subject/:repo/:package/:version/:file_path[?publish=0/1][?override=0/1][?explode=0/1]
    #
    # Bintray seems to expect the byte sequence of the file to be written straight out into the
    # HTTP request body, optionally via `Transfer-Encoding: chunked`. So we pass the `content` String
    # straight through to RestClient
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

    # GET /packages/:subject/:repo/:package/versions/:version/files[?include_unpublished=0/1]
    def get_all_files_in_version(repo_name, package_name, version_name)
      safe_repo = URI.escape(repo_name)
      safe_pkg = URI.escape(package_name)
      safe_ver = URI.escape(version_name)
      @http.get(
        rel("/packages/#{safe_username}/#{safe_repo}/#{safe_pkg}/versions/#{safe_ver}/files"),
        auth_headers)
    end

    def safe_username
      URI.escape(@username)
    end

    # Expand relative path
    def rel(slash_subpath)
      @base_url + slash_subpath
    end

    def api_headers
      { "Content-Type" => "application/json" }.update auth_headers
    end

    def auth_headers
      # As per RFC 7617
      cred = Base64.strict_encode64("#{@username}:#{@api_key}")
      { Authorization: "Basic #{cred}" }
    end

  end

end
