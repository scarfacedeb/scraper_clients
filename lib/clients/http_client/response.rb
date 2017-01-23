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

      def to_s(force_utf8: false)
        response = object.to_s
        return response unless force_utf8

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

      def to_html(**kargs)
        Nokogiri::HTML.parse to_s(**kargs)
      end

      def to_json(**kargs)
        JSON.parse to_s(**kargs), symbolize_names: true
      end

      def stream(size = HTTP::Connection::BUFFER_SIZE)
        while (chunk = object.body.readpartial(size))
          yield chunk
        end
      end
    end
  end
end
