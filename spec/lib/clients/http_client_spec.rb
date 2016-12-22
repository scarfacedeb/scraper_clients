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

      shared_examples "follow_redirects" do
        let(:url) { "http://ya.ru/redirect" }
        let(:redirect_to_url) { "http://ya.ru/final" }

        before do
          stub_request(:get, url).and_return(
            status: 301,
            headers: { location: redirect_to_url }
          )
          stub_request(:get, redirect_to_url).and_return(
            status: 200,
            body: "RESPONSE"
          )
        end

        it "follows redirects" do
          expect(response.to_s).to eq("RESPONSE")
          expect(WebMock).to have_requested(:get, url).once
          expect(WebMock).to have_requested(:get, redirect_to_url).once
        end
      end

      context "when follow_redirects is true" do
        let(:response) { subject.get(url, follow_redirects: true) }
        include_examples "follow_redirects"
      end

      context "when follow_redirects is nil" do
        let(:response) { subject.get(url) }
        include_examples "follow_redirects"
      end

      context "when follow_redirects is false" do
        let(:url) { "http://ya.ru/redirect" }
        let(:redirect_to_url) { "http://ya.ru/final" }
        let(:response) { subject.get(url, follow_redirects: false) }

        before do
          stub_request(:get, url).and_return(
            status: 301,
            headers: { location: redirect_to_url }
          )
        end

        it "DOESN'T follow redirects" do
          expect(response.status).to eq(301)
          expect(response.headers["Location"]).to eq(redirect_to_url)
          expect(WebMock).to have_requested(:get, url).once
          expect(WebMock).not_to have_requested(:get, redirect_to_url)
        end
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
