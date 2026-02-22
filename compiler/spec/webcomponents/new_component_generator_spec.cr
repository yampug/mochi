require "spec"
require "lexbor"
require "../../src/webcomponents/new_component_generator"
require "../code_test_utils"

describe NewComponentGenerator do
  it "generates correct bindings and paths" do
    # Simple case
    html = "<div><span>{count}</span><p class=\"{active}\">Test</p></div>"
    reactables = "['count', 'active']"
    bindings = {} of String => String
    
    gen = NewComponentGenerator.new
    comp = gen.generate("TestCmp", "test-cmp", "", html, reactables, bindings)
    
    js = comp.js_code
    
    # Check structure
    js.should contain("class TestCmpWebComp extends MochiComponent")
    js.should contain("constructor()")
    js.should contain("this.rubyComp = Opal.TestCmp.$new()")
    js.should contain("mount(target)")
    js.should contain("this.rubyComp.$mounted(this.shadow, this)")
    js.should contain("customElements.define('test-cmp', TestCmpWebComp)")
    
    # Check paths
    # div -> span (0) -> text (0) for {count}
    # r.childNodes[0].childNodes[0]
    js.should contain(".childNodes[0].childNodes[0]")
    
    # div -> p (1) for {active}
    # r.childNodes[1]
    js.should contain(".childNodes[1]")
    
    # Check update methods
    js.should contain("update_count(val)")
    js.should contain("textContent = val")
    
    js.should contain("update_active(val)")
    js.should contain("setAttribute(r.name, val)")
    
    # Check template registry
    js.should contain("window._mochi_templates['TestCmp']")
    # We replace {count} with space " "
    js.should contain("<span> </span>") 
  end
end
