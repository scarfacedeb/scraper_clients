module Clients
  class ProxyClient
    attr_reader :http_port, :http_host

    MAX_RESET_TRIES = 10

    def initialize(list_path, max_reset_tries: MAX_RESET_TRIES)
      @list_path = list_path
      @max_reset_tries = max_reset_tries

      fail "Proxy list doesn't exists at #{list_path}" unless @list_path.exists?
      reset!
    end

    def reset!(try: 0)
      host, port = proxy_list.sample.strip.split ":"
      if host && port
        @http_host = host
        @http_port = port
      elsif try < MAX_RESET_TRIES
        reset! try: try + 1
      end
    end

    def proxy_list
      @proxy_list ||= File.readlines(@list_path)
    end
  end
end
