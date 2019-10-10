
require 'open3'
require 'webrick'

require 'homebrew_automation/bintray/client.rb'

describe "HomebrewAutomation::Bintray::Client" do

  def port_open?(port)
    system("lsof -i :#{port}", out: '/dev/null')
  end

  def get_random_port
    port = rand 1025..10000
    if port_open?(port)
      get_random_port
    else
      port
    end
  end

  def echo_server_up?
    system(
      "curl http://localhost:#{@echo_server_port}",
      out: '/dev/null',
      err: '/dev/null'
    )
  end

  def await_cond(label, max_count: 20, wait_interval: 0.1, &block)
    reached = false
    count = 0
    until reached
      if count > max_count
        raise RuntimeError.new "Unable to acquire resource: #{label}"
      end
      reached = block.call
      count += 1
      sleep 0.1
    end
  end

  def cleanup(pid)
    if pid
      Process.kill("INT", pid)
    end
  end

  def parse_request_io(io)
    # https://stackoverflow.com/questions/17595205/how-to-parse-not-get-an-http-request-in-ruby
    req = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
    req.parse(io)
    req
  end

  @echo_server_port = nil
  @echo_server_pid = nil
  before :all do
    @echo_server_port = get_random_port
    @echo_server_pid = spawn(
      {"PORT" => @echo_server_port.to_s},
      "http-echo-server",
      out: '/dev/null'
    )
    Signal.trap("INT") { cleanup @echo_server_pid }
    Signal.trap("TERM") { cleanup @echo_server_pid }
    Signal.trap("QUIT") { cleanup @echo_server_pid }
    await_cond("echo_server") { echo_server_up? }
  end

  after :all do
    puts "The echo-server PORT was: #{@echo_server_port}"
    puts "The echo-server PID was: #{@echo_server_pid}"
    cleanup @echo_server_pid
  end

  describe "upload_file" do

    let (:user) { "johndoe" }
    let (:api_key) { "password" }

    let (:repo) { "repo-1" }
    let (:package) { "package-2" }
    let (:version) { "version-3" }
    let (:filepath) { "filepath-4.txt" }
    let (:contents) { "This is 100% a file!! Right? (Shell-dangerous characters here.)" }

    it "makes an equivalent request as a known curl command" do
      curl_command = %Q(curl \
        -u #{user.shellescape}:#{api_key.shellescape} \
        -X PUT \
        --data-binary #{contents.shellescape} \
        http://localhost:#{@echo_server_port.to_s.shellescape}/content/#{user.shellescape}/#{repo.shellescape}/#{package.shellescape}/#{version.shellescape}/#{filepath.shellescape}\\?publish=1\
        )
      _in, curl_out, _err = Open3.popen3(curl_command)
      expected_req = parse_request_io(curl_out)

      bclient = HomebrewAutomation::Bintray::Client.new(user, api_key, base_url: "http://localhost:#{@echo_server_port}")
      actual_req = parse_request_io(StringIO.new(bclient.upload_file(repo, package, version, filepath, contents).body))

      what_matters = [
        -> (r) { r.request_method },
        -> (r) { r.path },
        -> (r) { r.query_string },
        -> (r) { r.header['authorization'] },
        -> (r) { r.body },
      ]
      what_matters.each do |field|
        expect(field.call(actual_req)).to eq(field.call(expected_req))
      end
    end

  end

end
