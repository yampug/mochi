require "lexbor"
require "./web_component"
require "../html/conditional_processor"
require "../html/each_processor"

class NewComponentGenerator

  class Binding
    property path : Array(Int32)
    property type : Symbol # :text, :attr, :anchor
    property name : String? # attribute name or nil
    property value : String # variable name or anchor id
    
    def initialize(@path, @type, @value, @name = nil)
    end
  end

  def initialize
  end

  def generate(
    mochi_cmp_name : String,
    tag_name : String,
    css : String,
    html : String,
    reactables : String, # string "['a', 'b']"
    bindings : Hash(String, String),
    conditionals : Array(ConditionalBlock) = [] of ConditionalBlock,
    each_blocks : Array(EachBlock) = [] of EachBlock) : WebComponent

    # 1. Parse HTML and find bindings
    # We ignore the `bindings` hash from BindExtractor because we re-parse for {...}
    doc = Lexbor.new(html)
    doc_bindings = [] of Binding
    
    body = doc.body
    if body
      traverse(body, [] of Int32, doc_bindings)
    end
    
    # Clean HTML for template
    clean_html = body ? body.inner_html : ""
    
    # Parse reactables string to array
    # It comes as "['count', 'enabled']"
    react_vars = reactables.gsub(/[\[\]"']/, "").split(",").map(&.strip).reject(&.empty?)

    # 2. Generate JS
    js = String.build do |s|
        s << "class #{mochi_cmp_name}WebComp extends MochiComponent {\n"
        s << "  constructor() {\n"
        s << "    super();\n"
        s << "    this.rubyComp = Opal.#{mochi_cmp_name}.$new();\n"
        s << "  }\n\n"
        
        # Mount
        s << "  mount(target) {\n"
        s << "    this.rubyComp.$mounted(this.shadow, this);\n"
        s << "    const t = MochiComponent.getTemplate('#{mochi_cmp_name}');\n"
        s << "    const r = t.content.cloneNode(true);\n"
        s << "    this.dom_refs = {};\n"
        s << "    this.anchors = {};\n\n"
        
        # Paths
        doc_bindings.each_with_index do |b, i|
            # Path generation: r.childNodes[0].childNodes[1]...
            path_str = "r"
            b.path.each do |idx|
                path_str += ".childNodes[#{idx}]"
            end
            
            ref_name = "ref_#{i}"
            s << "    const #{ref_name} = #{path_str};\n"
            
            if b.type == :text
               # Clean variable name {count} -> count
               var_name = b.value.gsub(/[{}]/, "")
               s << "    if(!this.dom_refs['#{var_name}']) this.dom_refs['#{var_name}'] = [];\n"
               s << "    this.dom_refs['#{var_name}'].push({node: #{ref_name}, type: 'text'});\n"
               # Init value
               s << "    #{ref_name}.textContent = this.rubyComp.$get_#{var_name}();\n"
            elsif b.type == :attr
               var_name = b.value.gsub(/[{}]/, "")
               s << "    if(!this.dom_refs['#{var_name}']) this.dom_refs['#{var_name}'] = [];\n"
               s << "    this.dom_refs['#{var_name}'].push({node: #{ref_name}, type: 'attr', name: '#{b.name}'});\n"
               s << "    #{ref_name}.setAttribute('#{b.name}', this.rubyComp.$get_#{var_name}());\n"
            elsif b.type == :anchor
               # Anchor ID: "if-anchor-0"
               anchor_id = b.value.gsub(/<!--|-->/, "").strip
               s << "    this.anchors['#{anchor_id}'] = #{ref_name};\n"
            end
        end
        
        s << "    target.appendChild(r);\n"
        s << "    this.updateDerived();\n"
        s << "  }\n\n"
        
        # Update Methods (called from Ruby)
        react_vars.each do |v|
            s << "  update_#{v}(val) {\n"
            s << "    const refs = this.dom_refs['#{v}'];\n"
            s << "    if (refs) {\n"
            s << "      for (const r of refs) {\n"
            s << "        if (r.type === 'text') r.node.textContent = val;\n"
            s << "        else if (r.type === 'attr') r.node.setAttribute(r.name, val);\n"
            s << "      }\n"
            s << "    }\n"
            # Trigger derived updates
            s << "    this.updateDerived();\n"
            s << "  }\n\n"
        end
        
        # Derived
        s << "  updateDerived() {\n"
        conditionals.each do |c|
           s << "    this.updateConditional(#{c.id}, '#{mochi_cmp_name}_if_#{c.id}', () => {\n"
           s << "      let res = this.rubyComp.$__mochi_cond_#{c.id}();\n"
           s << "      return res !== false && res !== Opal.nil;\n"
           s << "    });\n"
        end
        each_blocks.each do |e|
           s << "    this.updateEach(#{e.id}, '#{mochi_cmp_name}_each_#{e.id}', () => {\n"
           s << "      let items = this.rubyComp.$__mochi_each_#{e.id}_items();\n"
           s << "      if (items && items.$to_a) return items.$to_a();\n"
           s << "      return items || [];\n"
           s << "    }, (item, index) => this.rubyComp.$__mochi_each_#{e.id}_key(item, index));\n"
        end
        s << "  }\n"
        s << "}\n"
        s << "customElements.define('#{tag_name}', #{mochi_cmp_name}WebComp);\n\n"
        
        # Template registry
        s << "if(!window._mochi_templates['#{mochi_cmp_name}']) {\n"
        s << "  const t = document.createElement('template');\n"
        s << "  t.innerHTML = `#{clean_html}`;\n"
        s << "  window._mochi_templates['#{mochi_cmp_name}'] = t;\n"
        
        conditionals.each do |c|
           s << "  const t#{c.id} = document.createElement('template');\n"
           s << "  t#{c.id}.innerHTML = `#{c.content}`;\n"
           s << "  window._mochi_templates['#{mochi_cmp_name}_if_#{c.id}'] = t#{c.id};\n"
        end
        each_blocks.each do |e|
           s << "  const t#{e.id} = document.createElement('template');\n"
           s << "  t#{e.id}.innerHTML = `#{e.content}`;\n"
           s << "  window._mochi_templates['#{mochi_cmp_name}_each_#{e.id}'] = t#{e.id};\n"
        end
        
        s << "}\n"
    end
    
    WebComponent.new("#{mochi_cmp_name}WebComp", js)
  end
  
  def traverse(node : Lexbor::Node, path : Array(Int32), bindings : Array(Binding))
    tag = node.tag_name
    
    if tag == "_text"
        text = node.tag_text
        if text =~ /\{([^}]+)\}/
             # Found binding
             var_name = $1
             # We store the *original* text? No, assume simple binding {var} for now.
             bindings << Binding.new(path, :text, "{#{var_name}}")
             node.tag_text_set(" ") # Placeholder
        end
    elsif tag == "_comment"
        text = node.tag_text
        if text.includes?("if-anchor") || text.includes?("each-anchor")
             bindings << Binding.new(path, :anchor, text)
        end
    else
        # Element
        if node.attributes
          remove_attrs = [] of String
          node.attributes.each do |k, v|
             if v =~ /\{([^}]+)\}/
                var_name = $1
                bindings << Binding.new(path, :attr, "{#{var_name}}", k)
                remove_attrs << k
             end
          end
          remove_attrs.each { |k| node.attribute_remove(k) }
        end
        
        # Children
        if node.children
           node.children.each_with_index do |child, i|
               traverse(child, path + [i], bindings)
           end
        end
    end
  end

end
