$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "clients/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "scraper_clients"
  s.version     = Clients::VERSION
  s.authors     = ["Andrew Volozhanin"]
  s.email       = ["scarfacedeb@gmail.com"]
  s.homepage    = "https://github.com/scarfacedeb/scraper_clients"
  s.summary     = "Clients to communicate with web and services"
  s.description = "Clients contains instruments to work with websites and local services."

  s.files = Dir["{lib,data}/**/*", "README.md"]
  s.test_files = Dir["spec/**/*", "bin/*"]

  s.add_dependency "addressable", "~> 2.3"
  s.add_dependency "http", "~> 4.3"
  s.add_dependency "net-telnet", "~> 0.1"
  s.add_dependency "nokogiri", "~> 1.6"

  s.add_development_dependency "rspec", "~> 3.5"
  s.add_development_dependency "webmock", "~> 2.1"
  s.add_development_dependency "pry-byebug"
end
