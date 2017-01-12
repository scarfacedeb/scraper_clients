require "clients/http_client"
require "clients/recaptcha/solver"

module Clients
  module Recaptcha
    class Client < Clients::HttpClient
      attr_writer :solver

      def get(url, **options, &block)
        response = super
        response = bypass_captcha(url, response) if captcha_protected?(response)
        response
      end

      def get_without_bypass(url, **options, &block)
        request :get, url, **options, &block
      end

      def solver
        @solver ||= Solver.new(self)
      end

      private

      def captcha_protected?(response)
        response.status == 403 &&
          response.to_s.include?("g-recaptcha-response")
      end

      def bypass_captcha(url, response)
        if has_cookies?
          reset_cookies
          response = get_without_bypass(url)
        end

        fail "captcha with empty cookie" if response.cookies.empty?

        solved_cookies = solver.solve(url, response)
        store_cookies solved_cookies

        solved_response = get_without_bypass(url, follow_redirects: false)
        reset_cookies

        solved_response
      end
    end
  end
end
