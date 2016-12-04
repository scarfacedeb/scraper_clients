require "net/ftp"
require "addressable/uri"
require "clients/url_decoder"

module Clients
  class FtpClient
    def get(url, &chunk_block)
      uri = Addressable::URI.parse url

      Net::FTP.open(uri.host) do |ftp|
        ftp.passive = true
        ftp.login
        ftp.getbinaryfile UrlDecoder.decode(uri.path), nil, &chunk_block
      end
    end
  end
end
