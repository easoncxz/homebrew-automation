
# Designed to be used via an `include`, because we use RSpec methods
# in here and need to preserve `self`.
module MyHelpers

  # Fabricate a most boring HTTP response
  #
  # To fake a response: https://stackoverflow.com/questions/770748
  # I have no idea why this has to be so complicated. I just want to
  # hand-fabricate my own RestClient::Response. People also keep
  # saying "webmock" or "FakeWeb" or something.
  def make_response(body:)
    net_http_res = Net::HTTPResponse.new(1.0, 200, 'OK')

    # Outermost call first:
    # https://www.rubydoc.info/gems/rest-client/RestClient/Response#create-class_method
    # https://www.rubydoc.info/gems/rest-client/RestClient/AbstractResponse#response_set_vars-instance_method
    # https://www.rubydoc.info/gems/rest-client/RestClient/AbstractResponse#history-instance_method
    request = double('Fake of maybe RestClient::Request')
    allow(request).to(receive('redirection_history').and_return(nil))

    RestClient::Response.create(body, net_http_res, request)
  end

end
