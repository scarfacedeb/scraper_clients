module Clients
  module UrlDecoder
    def self.decode(url)
      current_url, url = url, URI.decode(url) until url == current_url
      url
    end
  end
end
