require "spec_helper"

module Clients
  RSpec.describe HttpClient do
    let(:url) { "http://ya.ru/index.html" }

    before do
      stub_request(:get, url).and_return(
        status: 202,
        body: "RESPONSE",
        headers: {
          content_type: "image/png; charset=UTF-8"
        }
      )
    end

    describe "#get" do
      subject { described_class.new }
      let(:response) { subject.get(url) }

      it "makes a request to given url" do
        response
        expect(WebMock).to have_requested(:get, url)
      end

      it "modifies request from the block" do
        subject.get(url) do |request|
          request.headers(cookie: "was_here=1;")
        end

        expect(WebMock).to have_requested(:get, url).with(headers: { "Cookie" => "was_here=1;" }).once
      end

      it "returns wrapped response" do
        expect(response).to be_an_instance_of(HttpClient::Response)
        expect(response.to_s).to eq("RESPONSE")
        expect(response.code).to eq(202)
        expect(response.mime_type).to eq("image/png")
      end
    end
  end
end
