require "spec_helper"

module Clients
  RSpec.describe TorClient do
    let(:ok_prompt) { "250 OK\n" }
    let(:new_route_signal) { "SIGNAL NEWNYM" }
    let(:localhost) { double("telnet") }
    subject { described_class.new }

    describe "#switch_identity" do
      before do
        allow(Net::Telnet).to receive(:new).and_return localhost
        allow(localhost).to receive("cmd").and_return(ok_prompt)
        allow(localhost).to receive("close")

        allow(subject).to receive(:sleep).and_return(0)
      end

      it "throttles tor switch route command by 10 seconds", skip: true do
        time = Time.now

        Timecop.freeze(time)      { subject.switch_identity }
        Timecop.freeze(time + 2)  { subject.switch_identity }
        Timecop.freeze(time + 3)  { subject.switch_identity }
        Timecop.freeze(time + 5)  { subject.switch_identity }
        Timecop.freeze(time + 11) { subject.switch_identity }
        Timecop.freeze(time + 15) { subject.switch_identity }

        expect(subject).to have_received(:sleep).exactly(4)
        expect(localhost).to have_received("cmd").with(new_route_signal).exactly(4)
      end
    end
  end
end
