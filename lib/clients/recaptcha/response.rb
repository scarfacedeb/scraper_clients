module Clients
  module Recaptcha
    class Response < SimpleDelegator
      alias_method :object, :__getobj__

      def success?
        to_s[0..1] == "OK"
      end

      def data
        to_s[3..-1]
      end
    end
  end
end
