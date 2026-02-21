require "spec"
require "../../src/html/html_binding_extractor"

describe TreeSitter::HTMLBindingExtractor do
  it "extracts text bindings" do
    html = "<div><span>{@count}</span></div>"
    result = TreeSitter::HTMLBindingExtractor.extract(html)
    
    result.html.should eq "<div><span> </span></div>"
    result.bindings.size.should eq 1
    
    b = result.bindings.first
    b.type.should eq "text"
    b.expression.should eq "{@count}"
    b.path.should eq [0, 0, 0] # div -> span -> text
  end

  it "extracts attribute bindings" do
    html = "<button class={@active}></button>"
    result = TreeSitter::HTMLBindingExtractor.extract(html)
    
    result.html.should eq "<button></button>"
    result.bindings.size.should eq 1
    
    b = result.bindings.first
    b.type.should eq "attribute"
    b.expression.should eq "{@active}"
    b.attr_name.should eq "class"
    b.path.should eq [0] # button is first child of body
  end

  it "extracts multiple nested complex bindings" do
    html = "<div id={@id}><span>{@name}</span><button class={@btn_class}>Click</button></div>"
    result = TreeSitter::HTMLBindingExtractor.extract(html)

    result.html.should eq "<div><span> </span><button>Click</button></div>"
    result.bindings.size.should eq 3
    
    # 1. div id
    b1 = result.bindings.find(&.attr_name.==("id")).not_nil!
    b1.path.should eq [0]
    b1.type.should eq "attribute"
    b1.expression.should eq "{@id}"

    # 2. span text
    b2 = result.bindings.find(&.type.==("text")).not_nil!
    b2.path.should eq [0, 0, 0]
    b2.expression.should eq "{@name}"

    # 3. button class
    b3 = result.bindings.find(&.attr_name.==("class")).not_nil!
    b3.path.should eq [0, 1]
    b3.expression.should eq "{@btn_class}"
  end
end
