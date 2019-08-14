
require 'net/http'

require 'rest-client'

require 'homebrew_automation/bintray/version.rb'

require_relative '../my_helpers.rb'

describe "HomebrewAutomation::Bintray::Version" do
  include MyHelpers

  let (:fake_response) do
    make_response(body: File.read("spec/data/sample-files-list.json"))
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
