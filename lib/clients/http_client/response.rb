require "http"
require "nokogiri"

module Clients
  class HttpClient
    class Response < SimpleDelegator
      alias_method :object, :__getobj__

      def to_s
        response = object.to_s

        if response.encoding == Encoding::UTF_8
          response
        else
          response.force_encoding Encoding::UTF_8
        end
      end

      def to_html
        Nokogiri::HTML.parse to_s
      rescue
        to_s
      end

      def to_json
        JSON.parse to_s, symbolize_names: true
      rescue
        to_s
      end

      def stream(size = HTTP::Connection::BUFFER_SIZE)
        while (chunk = object.body.readpartial(size))
          yield chunk
        end
      end
    end
  end
end
