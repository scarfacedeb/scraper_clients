require "connection_pool"
require "clients/tor_client"
require "clients/http_client"

module Clients
  class << self
    attr_writer :logger

    def logger
      @logger ||= ::Logger.new("log/clients.log").tap do |logger|
        logger.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime} #{progname} TID-#{Thread.current.object_id.to_s(36)} #{severity}: #{msg}\n"
        end
      end
    end

    def setup_pool(size: 5, timeout: 300)
      pool = ConnectionPool.new(
        size:    size,
        timeout: timeout
      ) do
        tor_client = TorClient.new pool_num: current_pool_num(pool)
        HttpClient.new proxy: tor_client
      end
    end

    private

    def current_pool_num(pool)
      pool
        .instance_variable_get(:@available)
        .instance_variable_get(:@created)
    end
  end
end
