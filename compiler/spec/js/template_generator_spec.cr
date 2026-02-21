require "spec"
require "../../src/js/template_generator"

describe JS::TemplateGenerator do
  it "generates the global template registry" do
    js = JS::TemplateGenerator.generate_registry
    js.should contain("const _mochi_templates = {};")
  end

  it "generates a component class with statically cached parsing and mount cloning" do
    js = JS::TemplateGenerator.generate_component("Counter", "t1", "<span> </span>")
    
    # 1. Statically inject the template on file execution (only once per component)
    js.should contain("_mochi_templates['t1'] = document.createElement('template');")
    js.should contain("_mochi_templates['t1'].innerHTML = \"<span> </span>\";")
    
    # 2. Creates the class extending MochiComponent
    js.should contain("class Counter extends MochiComponent {")
    
    # 3. Mount method clones the fresh DOM tree
    js.should contain("mount(target) {")
    js.should match(/const [a-zA-Z0-9_]+ = _mochi_templates\['t1'\].content.cloneNode\(true\);/)
    
    # 4. Appends to target
    js.should match(/target\.appendChild\([a-zA-Z0-9_]+\);/)
  end
end
