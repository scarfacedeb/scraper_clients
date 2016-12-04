require "http"
require "openssl"
require "clients/http_client/response"
require "clients/http_client/errors"

module Clients
  class HttpClient
    attr_writer :user_agent
    attr_accessor :cookies, :proxy

    def initialize(proxy: nil, logger: nil)
      @proxy = proxy
      @logger = logger
    end

    def proxy?
      proxy
    end

    def has_cookies?
      cookies && cookies.any?
    end

    def get(url, **options, &block)
      make_request :get, url, **options, &block
    end

    def post(url, **options)
      make_request :post, url, **options, &block
    end

    def reset
      reset_user_agent
      reset_proxy
      reset_cookies
    end

    def reset_user_agent
      self.user_agent = nil
    end

    def reset_proxy
      return unless proxy

      log "Reset proxy to #{proxy.http_host}:#{proxy.http_port}"
      proxy.reset!
    end

    def reset_cookies
      self.cookies = nil
    end

    def user_agent
      @user_agent ||= sample_user_agent
    end

    private

    class << self
      attr_writer :user_agents

      def user_agents
        @user_agents ||= File.readlines user_agents_path
      end

      def user_agents_path
        File.join File.dirname(__FILE__), "../../data/user_agents.txt"
      end
    end

    def setup_request
      request = HTTP.follow.headers(user_agent: user_agent)
      request = request.cookies(cookies) if has_cookies?
      request = request.via(proxy.http_host, proxy.http_port.to_i) if proxy?
      request
    end

    def make_request(verb, url, **options, &block)
      options = options.merge(ssl_context: ssl_context)

      request = setup_request
      request = block.call(request) if block_given?

      log "#{verb.upcase} #{url}"
      response = request.request(verb, url, **options)

      store_cookies response

      Response.new response
    rescue
      raise HTTPError.new(url: url, proxy: proxy)
    end

    def store_cookies(response)
      self.cookies = response.cookies
    end

    def ssl_context
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
      ctx
    end

    def sample_user_agent
      self.class.user_agents.sample.strip
    end

    def log(msg)
      return unless @logger
      @logger.info msg
    end
  end
end
