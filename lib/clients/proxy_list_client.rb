module Clients
  class ProxyListClient
    DEFAULT_LIST_PATH = "/tmp/clients_proxy_list.txt".freeze

    attr_reader :host, :user, :password

    def self.cache_list(list_url, list_path = DEFAULT_LIST_PATH)
      response = HTTP.get(list_url)
      fail "Invalid list response: #{response.status}" unless response.status.success?
      File.open(list_path, "w") { |f| f << response.to_s }
    end

    def initialize(path = DEFAULT_LIST_PATH)
      @path = path
      select_proxy_from_list
    end

    def port
      @port.to_i
    end

    def to_s
      [host, port, user, password].compact.join(":")
    end

    def reset!
      select_proxy_from_list
    end

    private

    def select_proxy_from_list
      proxies = File.readlines(@path)
      address = proxies.sample
      @host, @port, @user, @password = address.split(":").map(&:strip)
    end
  end
end
