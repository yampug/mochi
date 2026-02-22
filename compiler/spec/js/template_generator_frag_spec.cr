require "spec"
require "../../src/js/template_generator"

describe JS::TemplateGenerator do
  it "generates if-block fragment templates alongside main components" do
    # Assuming JS::TemplateGenerator can generate isolated template fragment cache registers
    frag_html = "<p>Conditional Content</p>"
    js = JS::TemplateGenerator.generate_fragment("test_frag", frag_html)
    
    js.should contain("_mochi_templates['test_frag'] = document.createElement('template');")
    js.should contain("_mochi_templates['test_frag'].innerHTML = #{frag_html.inspect};")
  end
end
