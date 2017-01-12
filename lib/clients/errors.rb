module Clients
  class ClientError < StandardError; end

  class HttpClientError < ClientError
    # rubocop:disable Style/SpecialGlobalVars:
    def initialize(msg = "Failed request", url: nil, proxy: nil, cause: $!)
      msg << " at #{url}" if url
      msg << " via #{proxy.host}:#{proxy.port}" if proxy
      msg << " caused by #{cause.class}: #{cause.message}" if cause
      super msg
    end
  end

  class ProxyClientError < ClientError; end
  class RecaptchaError < ClientError; end
end
