require "spec"
require "../../src/html/conditional_processor"
require "../../src/js/conditional_block_generator"

describe JS::ConditionalBlockGenerator do
  it "generates correct logic for rendering conditional fragment blocks via createEffect" do
    block = ConditionalBlock.new("@show()", "<p>Visible</p>", 0, 10, 0, 4)
    paths = { 4 => [0, 2] }
    
    js = JS::ConditionalBlockGenerator.generate(block, "TestBase", paths)
    
    # 1. Checks wrapping Effect
    js.should contain("createEffect(() => {")
    
    # 2. Tracks rendering condition mapping to underlying template registry clone
    js.should contain("let frag = _mochi_templates['TestBase_if_4'].content.cloneNode(true);")
    
    # 3. Mounts exactly after the anchor
    js.should contain("this._dom_0_2.parentNode.insertBefore(frag, this._dom_0_2.nextSibling);")
    
    # 4. Correctly caches references to remove
    js.should contain("this._if_anchor_4_rendered = Array.from(frag.childNodes);")
    js.should contain("this._if_anchor_4_rendered.forEach(n => n.remove());")
  end
  
  it "generates accurate path walkers to initialize the anchor tracker state variable" do
    block = ConditionalBlock.new("@show()", "<p>Visible</p>", 0, 10, 0, 7)
    paths = { 7 => [1, 2, 0] }
    
    js = JS::ConditionalBlockGenerator.generate_walker(block, paths)
    
    js.should contain("this._if_anchor_7 = root.firstChild.nextSibling.firstChild.nextSibling.nextSibling.firstChild;")
    js.should contain("let this._if_anchor_7_rendered = null;")
  end
end
