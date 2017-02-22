require "http"
require "clients/errors"

module Clients
  class ProxyClient
    API_URL = "https://proxy6.net/api".freeze

    attr_reader :pool_num, :ip_version

    def initialize(
      pool_num: 0,
      api_url: API_URL,
      api_key: ENV["PROXY6_KEY"],
      ip_version: "4"
    )
      @pool_num = pool_num
      @api_url = api_url
      @api_key = api_key
      @proxy = fetch_proxy
      @ip_version = ip_version.to_s
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
      json = JSON.parse(response.to_s) if response.status.success?

      fail_on_invalid_list(response) if !response.status.success? || !json.key?("list")

      proxies = json.fetch("list")
      fail_on_invalid_list(response) if proxies.is_a?(Array)

      proxies = proxies.values.select { |h| h["version"] == @ip_version }
      fail_on_invalid_list(response) if proxies.empty?

      proxies
        .rotate(@pool_num)
        .first
    end

    def api_url
      [@api_url, @api_key, "getproxy/"].join("/")
    end

    def fail_on_invalid_list(response)
      fail ProxyClientError, "Invalid proxy list: #{response.status} #{response.to_s}"
    end
  end
end
