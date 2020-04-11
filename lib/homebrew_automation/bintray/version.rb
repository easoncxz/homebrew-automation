
require 'json'

module HomebrewAutomation
end

module HomebrewAutomation::Bintray

  # A representation of a Bintray +Version+
  #
  # As per Bintray, a +Version+ is part of a +Package+ is part of a +Repository+.
  class Version

    # The file to upload already exists on Bintray
    class FileAlreadyExists < StandardError
    end

    # @param client [Client] Connection to Bintray servers
    # @param logger [HomebrewAutomation::Logger]
    # @param repo_name [String]
    # @param package_name [String]
    # @param version_name [String]
    def initialize(client, logger, repo_name, package_name, version_name)
      @client = client
      @logger = logger
      @repo_name = repo_name
      @package_name = package_name
      @version_name = version_name
    end

    attr_reader :repo_name, :package_name, :version_name

    # Create this +Version+
    #
    # This assumes the +Package+ and +Repository+ already exists. If they do
    # not, consider creating them manually via the Bintray web UI.
    def create!
      @client.create_version(@repo_name, @package_name, @version_name)
    end

    # Upload a file to be part of this +Version+
    #
    # This is probably your Homebrew Bottle binary tarball.
    #
    # @param filename [String]
    # @param content [String] the bytes in the file
    def upload_file!(filename, content)
      begin
        @client.upload_file(
          @repo_name,
          @package_name,
          @version_name,
          filename,
          content)
      rescue RestClient::ExceptionWithResponse => e
        case e.response.code
        when 409
          raise FileAlreadyExists
        else
          raise e
        end
      end
    end

    # Download metadata about files that exist on Bintray for this +Version+
    #
    # @return [Hash] mapping from OS (as appears in part of the filenames) to sha256 checksum
    def gather_bottles
      resp = @client.get_all_files_in_version(@repo_name, @package_name, @version_name)
      _assert_match((200..207), resp.code)
      json = JSON.parse(resp.body)
      @logger.info!("All files in Bintray Version: #{json}")
      _assert_match(Array, json)
      pairs = json.map do |f|
        os = _parse_for_os(f['name'])
        checksum = f['sha256']
        [os, checksum]
      end.select { |o, _| not o.empty? }
      Hash[pairs]
    end

    def _assert_match(cond, x)
      unless cond === x
        p x
        raise StandardError.new(x)
      end
    end

    # @param bottle_filename [String] filename
    # @return [String] OS name
    def _parse_for_os(bottle_filename)
      File.extname(
        File.basename(bottle_filename, '.bottle.tar.gz')).
      sub(/^\./, '')
    end

  end

end
