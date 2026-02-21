require "spec"
require "../../src/js/dom_walker_generator"

describe JS::DomWalkerGenerator do
  it "generates walker for a simple direct path" do
    paths = [[0]]
    js = JS::DomWalkerGenerator.generate(paths)
    
    js.should contain("this._dom_0 = root.firstChild;")
  end
  
  it "generates walker using nextSibling for non-zero index" do
    paths = [[2]]
    js = JS::DomWalkerGenerator.generate(paths)
    
    js.should contain("this._dom_2 = root.firstChild.nextSibling.nextSibling;")
  end
  
  it "generates walker for deep nested paths" do
    paths = [[0, 1, 0]]
    js = JS::DomWalkerGenerator.generate(paths)
    
    # root.firstChild (for 0) .firstChild.nextSibling (for 1) .firstChild (for 0)
    js.should contain("this._dom_0_1_0 = root.firstChild.firstChild.nextSibling.firstChild;")
  end
  
  it "generates multiple paths" do
    paths = [[0], [1, 2]]
    js = JS::DomWalkerGenerator.generate(paths)
    
    js.should contain("this._dom_0 = root.firstChild;")
    js.should contain("this._dom_1_2 = root.firstChild.nextSibling.firstChild.nextSibling.nextSibling;")
  end
  
  it "uses custom root name" do
    paths = [[0]]
    js = JS::DomWalkerGenerator.generate(paths, "el")
    
    js.should contain("this._dom_0 = el.firstChild;")
  end
end
