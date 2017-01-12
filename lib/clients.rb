require "clients/tor_client"
require "clients/http_client"
require "clients/proxy_client"
require "clients/recaptcha/client"

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
  end
end
