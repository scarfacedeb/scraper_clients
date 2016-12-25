require "spec_helper"

module Clients
  RSpec.describe HttpClient do
    subject { described_class.new }

    describe "#get" do
      let(:url) { "http://ya.ru/index.html" }
      let(:response) { subject.get(url) }

      before do
        stub_request(:get, url).and_return(
          status: 202,
          body: "RESPONSE",
          headers: {
            content_type: "image/png; charset=UTF-8"
          }
        )
      end

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

    describe "#proxy?" do
      context "when proxy has been used" do
        let(:proxy) { instance_spy("Clients::TorProxy") }
        subject { described_class.new proxy: proxy }

        it "returns true" do
          expect(subject.proxy?).to eq(true)
        end
      end

      context "when proxy has NOT been used" do
        it "returns false" do
          expect(subject.proxy?).to eq(false)
        end
      end
    end

    describe "#has_cookies?" do
      context "when client has cookies" do
        let(:cookie) { HTTP::Cookie.new("group", "admin", domain: "example.com", path: "/") }

        it "returns true" do
          subject.cookies << cookie
          expect(subject).to have_cookies
        end
      end

      context "when proxy has NOT been used" do
        it "returns false" do
          expect(subject).not_to have_cookies
        end
      end
    end

    describe "#store_cookies" do
      let(:old_cookie) { HTTP::Cookie.new("group", "admin", domain: "example.com", path: "/") }
      let(:new_cookie) { HTTP::Cookie.new("uid", "u12345", domain: "ya.ru", path: "/admin") }
      let(:cookies) { HTTP::CookieJar.new }

      before do
        subject.cookies << old_cookie
        cookies << new_cookie
      end

      it "adds given cookies from the response" do
        subject.store_cookies cookies
        expect(subject.cookies.to_a).to contain_exactly(old_cookie, new_cookie)
      end

      it "sents new and old cookies with the new request" do
        url = "https://placeholder.com"
        stub_request(:get, url).and_return(status: 200)

        subject.store_cookies cookies
        subject.get(url)

        expect(WebMock).to have_requested(:get, url)
          .with(headers: { "Cookie" => "group=admin; uid=u12345" })
          .once
      end
    end

    describe "#reset_cookies" do
      let(:cookie) { HTTP::Cookie.new("group", "admin", domain: "example.com", path: "/") }

      it "reset client cookies" do
        subject.cookies << cookie
        subject.reset_cookies
        expect(subject.cookies).to be_empty
      end
    end

    describe "#reset_user_agent" do
      it "reset client user agent" do
        subject.user_agent
        expect(subject.user_agent).not_to be_empty

        # Need to stub sample, because it's not deterministic
        allow(subject).to receive(:sample_user_agent).and_return("UA")

        subject.reset_user_agent

        expect(subject.user_agent).to eq("UA")
      end
    end

    describe "#reset_proxy" do
      context "when proxy has been used" do
        let(:proxy) { instance_spy("Clients::TorProxy") }
        subject { described_class.new proxy: proxy }

        it "calls reset on proxy" do
          subject.reset_proxy
          expect(proxy).to have_received(:reset!).once
        end
      end

      context "when proxy has NOT been used" do
        subject { described_class.new }

        it "does nothing" do
          expect { subject.reset_proxy }.not_to raise_error
        end
      end
    end
  end
end
