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
    
    it "supports global property access" do
      js = QuickJS::Runtime.new
      js["myVar"] = 42
      js["myVar"].to_i.should eq 42
      js.finalize
    end

    it "supports function calls on global object" do
      js = QuickJS::Runtime.new
      js.eval("function add(a, b) { return a + b; }")
      js.call("add", 10, 20).to_i.should eq 30
      js.finalize
    end
  end

  describe QuickJS::Value do
    it "supports object property access" do
      js = QuickJS::Runtime.new
      obj = js.eval("({a: 1})")
      obj["a"].to_i.should eq 1
      obj["b"] = 2
      obj["b"].to_i.should eq 2
      js.finalize
    end

    it "supports array operations" do
      js = QuickJS::Runtime.new
      arr = js.eval("[1, 2, 3]")
      arr.size.should eq 3
      
      doubled = arr.map { |v| v.to_i * 2 }
      doubled.should eq [2, 4, 6]
      
      js.finalize
    end
    
    it "supports function calls on values" do
      js = QuickJS::Runtime.new
      func = js.eval("(function(a) { return a * a; })")
      func.call(5).to_i.should eq 25
      js.finalize
    end

    it "supports complex conversions" do
       js = QuickJS::Runtime.new
       
       arr = js.eval("[10, 20]")
       crystal_arr = arr.to_a
       crystal_arr.size.should eq 2
       crystal_arr[0].to_i.should eq 10
       
       obj = js.eval("({x: 1, y: 2})")
       h = obj.to_h
       h["x"].to_i.should eq 1
       h["y"].to_i.should eq 2
       
       js.finalize
    end
  end
end
