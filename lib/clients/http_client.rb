require "http"
require "openssl"
require "clients/http_client/response"
require "clients/errors"

module Clients
  class HttpClient
    attr_writer :user_agent, :cookies
    attr_accessor :proxy

    def initialize(
      proxy: nil,
      logger: nil
    )
      @proxy = proxy
      @logger = logger
    end

    def proxy?
      !!proxy
    end

    def has_cookies?
      cookies.any?
    end

    def get(url, **options, &block)
      request :get, url, **options, &block
    end

    def post(url, **options, &block)
      request :post, url, **options, &block
    end

    def head(url, **options, &block)
      request :head, url, **options, &block
    end

    def request(verb, url, **options)
      options = options.merge(ssl_context: ssl_context)

      request = setup_request options.delete(:follow_redirects)
      request = yield request if block_given?

      response = make_request(request, verb, url, **options)

      Response.new response
    rescue
      raise HttpClientError.new(url: url, proxy: proxy)
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

      log "Reset proxy to #{proxy.host}:#{proxy.port}"
      proxy.reset!
    end

    def store_cookies(cookies)
      return if cookies.empty?
      cookies.each do |cookie|
        self.cookies << cookie
      end
    end

    def reset_cookies
      @cookies = nil
    end

    def cookies
      @cookies ||= HTTP::CookieJar.new
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

    def setup_request(follow_redirects)
      follow_redirects = true if follow_redirects.nil?

      request = HTTP.headers(user_agent: user_agent)
      request = request.follow if follow_redirects
      request = request.cookies(cookies) if has_cookies?
      request = request.via(proxy.host, proxy.port, proxy.user, proxy.password) if proxy?

      request
    end

    def make_request(request, verb, url, **options)
      start = Time.now

      response = request.request(verb, url, **options)

      log_request(
        verb: verb.to_s.upcase,
        url: url,
        duration: (Time.now - start),
        status: response.status.code,
        mime_type: response.content_type.mime_type
      )

      response
    end

    def ssl_context
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
      ctx
    end

    def sample_user_agent
      self.class.user_agents.sample.strip
    end

    def log_request(req)
      return unless @logger

      msg = "#{req[:verb]} #{req[:url]} (#{req[:duration]}s)"

      log req.merge(message: msg, proxy: proxy&.to_s)
    end

    def log(msg_or_hash)
      return unless @logger
      @logger.info msg_or_hash
    end
  end
end
