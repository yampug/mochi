require "spec"
require "../../src/quickjs"

describe QuickJS do
  describe QuickJS::RuntimeBuilder do
    it "builds a runtime with configuration" do
      js = QuickJS.build do |b|
        b.memory_limit(1024 * 1024)
      end
      js.finalize
    end
  end

  describe QuickJS::Sandbox do
    it "can be initialized" do
      sb = QuickJS::Sandbox.new
      sb.eval("1+1").to_i.should eq 2
      sb.finalize
    end
  end
end
