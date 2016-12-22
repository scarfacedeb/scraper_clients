require "spec_helper"

module Clients
  class HttpClient
    RSpec.describe Response do
      let(:headers) { {} }
      let(:body) { "BODY" }
      let(:response) {
        HTTP::Response.new(
          status: @status || 200,
          version: "1.1",
          headers: headers,
          body: body
        )
      }
      subject { described_class.new(response) }

      describe "#to_s" do
        it "returns response body" do
          expect(subject.to_s).to eq("BODY")
        end

        context "when response doesn't have valid charset" do
          let(:body) { "Correct Ответ".force_encoding Encoding::CP1251 }

          it "returns response body in UTF-8 encoding" do
            response = subject.to_s

            expect(response.encoding).to eq(Encoding::UTF_8)
            expect(response).to eq("Correct Ответ")
          end
        end

        context "when response have valid charset - windows-1251" do
          let(:headers) {
            {
              "Content-Type" => "text/html; charset=windows-1251"
            }
          }
          let(:body) { "Correct Ответ".encode Encoding::CP1251 }

          it "returns response body in UTF-8 encoding" do
            response = subject.to_s

            expect(response.encoding).to eq(Encoding::UTF_8)
            expect(response).to eq("Correct Ответ")
          end
        end
      end

      describe "#to_html" do
        let(:html) { subject.to_html }
        it "returns parsed response body" do
          expect(html).to be_an_instance_of(Nokogiri::HTML::Document)
          expect(html.to_s).to include("<body><p>BODY</p></body>")
        end
      end

      describe "#stream" do
        let(:url) { "http://example.com" }
        let(:response) { Clients::HttpClient.new.get(url) }

        before do
          stub_request(:get, url).and_return(body: body)
        end

        it "streams response body" do
          expect { |b| subject.stream(1, &b) }.to yield_successive_args("B", "O", "D", "Y")
        end

        context "buffer size is not specified" do
          it "streams response body" do
            expect { |b| subject.stream(&b) }.to yield_successive_args("BODY")
          end
        end
      end

      context "when response comes in plain text format" do
        let(:body) { "[{\"brand\":\"ZANUSSI\",\"product_code\":\"91460370200\"}]" }
        let(:parsed_body) { [{brand: "ZANUSSI", product_code: "91460370200"}] }

        describe "#to_json" do
          it "returns parsed json body" do
            allow(subject).to receive(:to_s).and_return(body)
            expect(subject.to_json).to eq parsed_body
          end
        end
      end
    end
  end
end
