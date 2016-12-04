require "spec_helper"

RSpec.describe Clients do
  describe ".setup_pool" do
    let(:pool) { described_class.setup_pool size: 2, timeout: 100 }

    it "creates connection pool" do
      expect(pool).to be_an_instance_of(ConnectionPool)
    end

    it "creates pool with http clients and tor proxies" do
      pool.with do |client|
        expect(client).to be_an_instance_of(Clients::HttpClient)
        expect(client.proxy).to be_an_instance_of(Clients::TorClient)
      end
    end
  end
end
