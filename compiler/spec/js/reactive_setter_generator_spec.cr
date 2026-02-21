require "spec"
require "../../src/js/reactive_setter_generator"

describe JS::ReactiveSetterGenerator do
  it "generates a simple text node setter" do
    ops = [
      TreeSitter::DomOperation.new([0, 1], "text")
    ]
    js = JS::ReactiveSetterGenerator.generate("@count", ops)
    
    js.should contain("get count() { return this._count; }")
    js.should contain("set count(val) {")
    js.should contain("if (val === this._count) return;")
    js.should contain("this._count = val;")
    js.should contain("this._dom_0_1.data = val;")
  end
  
  it "generates an attribute setter" do
    ops = [
      TreeSitter::DomOperation.new([0], "attribute", "class")
    ]
    js = JS::ReactiveSetterGenerator.generate("@active", ops)
    
    js.should contain("get active() { return this._active; }")
    js.should contain("this._dom_0.setAttribute(\"class\", val);")
  end
  
  it "generates setter for multiple target DOM operations" do
    ops = [
      TreeSitter::DomOperation.new([0, 0], "text"),
      TreeSitter::DomOperation.new([0], "attribute", "title")
    ]
    js = JS::ReactiveSetterGenerator.generate("@name", ops)
    
    js.should contain("this._dom_0_0.data = val;")
    js.should contain("this._dom_0.setAttribute(\"title\", val);")
  end
end
