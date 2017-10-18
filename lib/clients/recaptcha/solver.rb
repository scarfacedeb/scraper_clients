require "clients/errors"
require "clients/recaptcha/response"

module Clients
  module Recaptcha
    class Solver
      INIT_URL = Addressable::URI.parse("http://2captcha.com/in.php").freeze
      SOLVE_STATUS_URL = Addressable::URI.parse("http://2captcha.com/res.php").freeze

      attr_reader :client, :captcha_key, :sleep_duration

      def initialize(client, captcha_key: ENV["CAPTCHA_SOLVER_KEY"], sleep_duration: 5)
        @client = client
        @captcha_key = captcha_key
        @sleep_duration = sleep_duration
      end

      def solve(banned_url, response)
        site_key = find_site_key(response)
        solved_path = find_solve_url(response)

        id = init_solver banned_url, site_key
        token = get_solution id

        solved_response = solve_captcha banned_url, solved_path, token
        solved_response.cookies
      end

      private

      def init_url(banned_url, site_key)
        url = INIT_URL.dup
        url.query_values = {
          key: captcha_key,
          method: "userrecaptcha",
          googlekey: site_key,
          url: banned_url
        }
        url
      end

      def status_url(id, tries = 0)
        url = SOLVE_STATUS_URL.dup
        url.query_values = {
          key: captcha_key,
          action: "get",
          id: id,
          try: tries
        }
        url
      end

      def solved_url(banned_url, solved_path, token)
        url = Addressable::URI.parse(banned_url)
        url.path = solved_path
        url.query_values = { "g-recaptcha-response": token }
        url
      end

      def find_site_key(response)
        key = response.to_s.match(/data-sitekey=\"(.+?)\"/) { |m| m[1] }
        fail RecaptchaError, "Empty sitekey in recaptcha form" unless key
        key
      end

      def find_solve_url(response)
        url = response.to_s.match(/action=\"(.+?)\"/) { |m| m[1] }
        fail RecaptchaError, "Empty action in recaptcha form" unless url
        url
      end

      def init_solver(banned_url, site_key)
        url = init_url banned_url, site_key
        response = wrap_response client.get_without_bypass(url)
        fail RecaptchaError, response.to_s unless response.success?
        response.data
      end

      def get_solution(id)
        tries = 0
        response = nil

        until response
          fail RecaptchaError, "Solve timeout after 10 tries" if tries > 10

          sleep sleep_duration
          response = check_status id, tries
          tries += 1
        end

        response.data
      end

      def check_status(id, tries)
        url = status_url id, tries
        response = wrap_response client.get_without_bypass(url)
        response if response.success?
      end

      def solve_captcha(banned_url, solved_path, token)
        url = solved_url banned_url, solved_path, token
        response = client.get_without_bypass(url, follow_redirects: false) do |request|
          request.headers(referer: banned_url)
        end

        fail RecaptchaError, "Unable to solve recaptcha" if response.status.redirect?
        response
      end

      def wrap_response(response)
        Recaptcha::Response.new response
      end
    end
  end
end
