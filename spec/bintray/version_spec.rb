
require 'net/http'

require 'rest-client'

require 'homebrew_automation/bintray/version.rb'

describe "HomebrewAutomation::Bintray::Version" do

  let (:fake_response) do
    response_filepath = "spec/data/sample-files-list.json"

    # To fake a response: https://stackoverflow.com/questions/770748
    # I have no idea why this has to be so complicated. I just want to
    # hand-fabricate my own RestClient::Response. People also keep
    # saying "webmock" or "FakeWeb" or something.
    net_http_res = Net::HTTPResponse.new(1.0, 200, 'OK')
    request = ->() do
      # Outermost call first:
      # https://www.rubydoc.info/gems/rest-client/RestClient/Response#create-class_method
      # https://www.rubydoc.info/gems/rest-client/RestClient/AbstractResponse#response_set_vars-instance_method
      # https://www.rubydoc.info/gems/rest-client/RestClient/AbstractResponse#history-instance_method
      r = double('Maybe RestClient::Request')
      allow(r).to(receive('redirection_history').and_return(nil))
      r
    end.call
    RestClient::Response.create(
      File.read(response_filepath),
      net_http_res,
      request)
  end
  let (:expected_bottles) do
    # coupled with above response_filepath
    {'high_sierra' => "d985f1ec04a7a2c1cbf493362045f436e626e82e3e00b63e279504089c0ac2fd"}
  end

  let (:d_bintray_client) { double('bintray_client') }
  let (:repo) { 'my-repo' }
  let (:package) { 'my-package' }
  let (:version) { 'version-1' }
  let (:bintray_version) do
    HomebrewAutomation::Bintray::Version.new(
      d_bintray_client,
      repo,
      package,
      version)
  end

  describe 'gather_bottles' do

    it 'can figure out the OS and sha256 from a Bintray JSON response' do
      expect(d_bintray_client).
        to(receive(:get_all_files_in_version)).
        with(repo, package, version).
        and_return(fake_response)
      bottles = bintray_version.gather_bottles
      expect(bottles).to(eq(expected_bottles))
    end

  end

end
