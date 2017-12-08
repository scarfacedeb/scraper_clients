require "clients/errors"
require "clients/proxy6_client"
require "clients/proxy_list_client"

module Clients
  class ProxyClient
    def self.from_env
      case ENV["CLIENTS_PROXY_CLIENT"]
      when "proxy6" then Proxy6Client.new
      when "list" then ProxyListClient.new
      end
    end
  end
end
