module Clients
  class HttpClient
    class HTTPError < StandardError
      # rubocop:disable Style/SpecialGlobalVars:
      def initialize(msg = "Failed request", url: nil, proxy: nil, cause: $!)
        msg << " at #{url}" if url
        msg << " via #{proxy.http_host}:#{proxy.http_port}" if proxy
        msg << " caused by #{cause.class}: #{cause.message}" if cause
        super msg
      end
    end
  end
end
