require "http"

module Clients
  class ProxyClient
    API_URL = "https://proxy6.net/api".freeze

    attr_reader :pool_num

    def initialize(
      pool_num:,
      api_url: API_URL,
      api_key: ENV["PROXY6_KEY"]
    )
      @pool_num = pool_num
      @api_url = api_url
      @api_key = api_key
      @proxy = fetch_proxy
    end

    def host
      @proxy["host"]
    end

    def port
      @proxy["port"].to_i
    end

    def user
      @proxy["user"]
    end

    def password
      @proxy["pass"]
    end

    def reset!
      @proxy = fetch_proxy
    end

    private

    def fetch_proxy
      response = HTTP.accept(:json).get(api_url, params: { state: "active" })
      proxies = JSON.parse(response.to_s).fetch("list")
      proxies.values.rotate(@pool_num).first
    end

    def api_url
      [@api_url, @api_key, "get_proxy/"].join("/")
    end
  end
end
