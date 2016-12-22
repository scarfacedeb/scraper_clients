require "http"
require "nokogiri"

module Clients
  class HttpClient
    class Response < SimpleDelegator
      alias_method :object, :__getobj__

      DEFAULT_ENCODING = Encoding::UTF_8

      def success?
        object.status.success?
      end

      def fail?
        !success?
      end

      def to_s
        response = object.to_s

        if object.charset
          response
            .encode(DEFAULT_ENCODING)
            .scrub("_")
        else
          response
            .force_encoding(DEFAULT_ENCODING)
            .scrub("_")
        end
      end

      def to_html
        Nokogiri::HTML.parse to_s
      end

      def to_json
        JSON.parse to_s, symbolize_names: true
      end

      def stream(size = HTTP::Connection::BUFFER_SIZE)
        while (chunk = object.body.readpartial(size))
          yield chunk
        end
      end
    end
  end
end
