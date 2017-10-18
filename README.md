Clients
=======

Clients contains instruments that are suited to make requests during scraping.

It includes following clients:

- **HttpClient:** to fetch web pages or files
- **FtpClient:** to fetch files from ftp
- **TorClient:** to proxy client requests via tor
- **ProxyClient:** to proxy client request via any of proxy6 proxies

It also implements a special wrapper around of HttpClient:

- **Recaptcha::Client:** to visit websites behind recaptcha blocks

Important ENV variables:

- **PROXY6_KEY:** API key for proxy6.net service
- **CAPTCHA_SOLVER_KEY:** API key for 2captcha.com service
- **TOR_PORT:** Base port for tor SOCKS5 proxy
- **TOR_CONTROL_PORT:** Base port for tor controls
- **HTTP_TOR_PORT:** Base port for http middleman proxy for TorClient (e.g. polipo)
