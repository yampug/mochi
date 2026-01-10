require "spec"
require "../../src/quickjs"

describe QuickJS do
  describe QuickJS::Runtime do
    it "can be initialized and finalized" do
      js = QuickJS::Runtime.new
      js.finalize
    end

    it "evaluates simple expressions" do
      js = QuickJS::Runtime.new
      result = js.eval("1 + 1")
      result.to_i.should eq 2
      js.finalize
    end

    it "handles different types" do
      js = QuickJS::Runtime.new
      
      js.eval("10").to_i.should eq 10
      js.eval("'hello'").to_s.should eq "hello"
      js.eval("true").to_bool.should be_true
      js.eval("null").null?.should be_true
      js.eval("undefined").undefined?.should be_true
      
      js.finalize
    end

    it "handles errors" do
      js = QuickJS::Runtime.new
      
      expect_raises(QuickJS::ReferenceError) do
        js.eval("unknownVariable")
      end
      
      expect_raises(QuickJS::SyntaxError) do
        js.eval("syntax error !!!")
      end
      
      js.finalize
    end
    
    it "manages memory with finalizers" do
       js = QuickJS::Runtime.new
       100.times do
         v = js.eval("'test'")
         v.finalize
       end
       js.finalize
    end

    it "supports eval from file" do
         path = "test_script.js"
         File.write(path, "2 * 4")
         js = QuickJS::Runtime.new
         js.eval_file(path).to_i.should eq 8
         js.finalize
         File.delete(path)
    end
  end
end
