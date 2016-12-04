require "net/telnet"
require "ostruct"

# Proxy to Tor
#
# From http://martincik.com/?p=402
module Clients
  class TorClient
    DEFAULT_PORT = 9050
    DEFAULT_CONTROL_PORT = 9051
    DEFAULT_HTTP_PORT = 8080
    OK_STATUS = "250 OK\n".freeze

    extend Forwardable

    attr_reader :config, :threshold, :pool_num

    def_delegators :@config,
      :host, :port, :http_port, :http_host

    # rubocop:disable Metrics/MethodLength
    def initialize(options = {})
      options = {
        host:            "localhost",
        port:            (ENV["TOR_PORT"] || DEFAULT_PORT).to_i,
        control_port:    (ENV["TOR_CONTROL_PORT"] || DEFAULT_CONTROL_PORT).to_i,
        http_host:       "localhost",
        http_port:       (ENV["HTTP_TOR_PORT"] || DEFAULT_HTTP_PORT).to_i,
        circuit_timeout: 10,
        throttle_by:     10, # .seconds implied
        pool_num:        nil
      }.merge(options)

      @pool_num = options.delete(:pool_num)
      @config = OpenStruct.new options

      setup_pool
    end

    def proxy_address
      "127.0.0.1:#{config.port}"
    end

    # Switch routes
    def switch_identity
      throttle do
        client = Net::Telnet.new(
          "Host"    => config.host,
          "Port"    => config.control_port,
          "Timeout" => config.circuit_timeout,
          "Prompt"  => Regexp.new(OK_STATUS)
        )

        authenticate client
        new_route client

        client.close
      end
    end
    alias_method :reset!, :switch_identity

    private

    def throttle
      scheduled = if check_threshold
                    update_threshold
                    :now
                  else
                    schedule_switch
                  end

      if scheduled == :now
        yield
      else
        sleep until_next_switch_time

        if scheduled
          update_threshold
          yield
        end
      end
    end


    def authenticate(client)
      client.cmd("AUTHENTICATE") do |c|
        fail "cannot authenticate to Tor!" unless c == OK_STATUS
      end
    end

    def new_route(client)
      client.cmd("SIGNAL NEWNYM") do |c|
        fail "cannot switch Tor to new route!" unless c == OK_STATUS
      end
    end

    private

    def setup_pool
      return unless pool_num

      config.port = config.port + 2*pool_num
      config.control_port = config.control_port + 2*pool_num
    end

    def check_threshold
      !threshold || (next_switch_time < Time.now)
    end

    def next_switch_time
      threshold + config.throttle_by
    end

    def until_next_switch_time
      diff = next_switch_time - Time.now
      diff < 0 ? 0 : diff
    end

    def schedule_switch
      return if @scheduled
      @scheduled = true
    end

    def update_threshold
      @threshold = Time.now
      @scheduled = false
    end

    def reset_threshold
      @threshold = nil
    end
  end
end
