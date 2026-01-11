require "spec"
require "../../src/quickjs"

describe QuickJS::Opal::Compiler do
  it "compiles ruby code to javascript" do
    compiler = QuickJS::Opal::Compiler.new
    js_code = compiler.compile("1 + 2")
    js_code.should contain("$rb_plus(1, 2)")
    compiler.finalize
  end

  it "evaluates ruby code" do
    compiler = QuickJS::Opal::Compiler.new
    result = compiler.eval("1 + 2")
    result.to_i.should eq 3
    compiler.finalize
  end

  it "handles ruby strings" do
    compiler = QuickJS::Opal::Compiler.new
    result = compiler.eval("'hello'.upcase")
    result.to_s.should eq "HELLO"
    compiler.finalize
  end

  it "can define and call ruby methods" do
    compiler = QuickJS::Opal::Compiler.new
    compiler.eval("def greet(name); 'Hello ' + name; end")
    result = compiler.eval("greet('Crystal')")
    result.to_s.should eq "Hello Crystal"
    compiler.finalize
  end
end
