require "spec_helper"

module Clients
  class HttpClient
    RSpec.describe Response do
      let(:headers) { {} }
      let(:body) { "BODY" }
      let(:status) { 200 }
      let(:response) {
        HTTP::Response.new(
          status: status,
          version: "1.1",
          headers: headers,
          body: body
        )
      }
      subject { described_class.new(response) }

      describe "#success?" do
        context "when response has succeeded" do
          let(:status) { 200 }
          it "returns true" do
            is_expected.to be_success
          end
        end

        context "when response has failed" do
          let(:status) { 502 }
          it "returns false" do
            is_expected.not_to be_success
          end
        end
      end

      describe "#fail?" do
        context "when response has failed" do
          let(:status) { 400 }
          it "returns true" do
            is_expected.to be_fail
          end
        end

        context "when response has succeeded" do
          let(:status) { 201 }
          it "returns false" do
            is_expected.not_to be_fail
          end
        end
      end

      describe "#to_s" do
        it "returns response body" do
          expect(subject.to_s).to eq("BODY")
        end

        context "when force_utf8 hasn't been provided" do
          let(:body) { "\x89PNG\r\n\x1A\n\x00\x00\x00" }
          it "sets force_utf8 to FALSE by default" do
            expect(subject.to_s).to eq(body)
          end
        end

        context "when force_utf8 is FALSE" do
          shared_examples "unmodified body" do
            it "returns unmodified response body" do
              expect(subject.to_s(force_utf8: false)).to eq(body)
            end
          end

          context "when response doesn't have valid charset" do
            let(:body) { "Correct Ответ".force_encoding Encoding::CP1251 }
            include_examples "unmodified body"
          end

          context "when response is binary" do
            let(:body) { "\x89PNG\r\n\x1A\n\x00\x00\x00" }
            include_examples "unmodified body"
          end
        end

        context "when force_utf8 is TRUE" do
          context "when response doesn't have valid charset" do
            let(:body) { "Correct Ответ".force_encoding Encoding::CP1251 }

            it "returns response body in UTF-8 encoding" do
              response = subject.to_s force_utf8: true

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
              response = subject.to_s force_utf8: true

              expect(response.encoding).to eq(Encoding::UTF_8)
              expect(response).to eq("Correct Ответ")
            end
          end
        end
      end

      describe "#to_html" do
        it "returns parsed response body" do
          html = subject.to_html
          expect(html).to be_an_instance_of(Nokogiri::HTML::Document)
          expect(html.to_s).to include("<body><p>BODY</p></body>")
        end

        context "when force_utf8 is TRUE" do
          let(:body) { "Correct Ответ".force_encoding Encoding::CP1251 }

          it "returns parsed response body in valid UTF_8 encodin" do
            html = subject.to_html(force_utf8: true)
            expect(html).to be_an_instance_of(Nokogiri::HTML::Document)
            expect(html.to_s).to include("<body><p>Correct Ответ</p></body>")
          end
        end
      end

      describe "#to_json" do
        let(:body) { "[{\"brand\":\"Фирма ZANUSSI\",\"product_code\":\"91460370200\"}]" }
        let(:parsed_body) { [{brand: "Фирма ZANUSSI", product_code: "91460370200"}] }

        it "returns parsed json body" do
          expect(subject.to_json).to eq parsed_body
        end

        context "when force_utf8 is TRUE" do
          let(:body) { super().force_encoding Encoding::CP1251 }

          it "returns parsed json body" do
            expect(subject.to_json(force_utf8: true)).to eq parsed_body
          end
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
    end
  end
end
