require "lexbor"
require "./web_component"
require "../html/conditional_processor"
require "../html/each_processor"

class ComponentGenerator

  class Binding
    property path : Array(Int32)
    property type : Symbol # :text, :html, :attr, :anchor
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
    reactables : String,
    bindings : Hash(String, String),
    conditionals : Array(ConditionalBlock) = [] of ConditionalBlock,
    each_blocks : Array(EachBlock) = [] of EachBlock) : WebComponent

    # 1. Parse HTML and find bindings
    doc = Lexbor.new(html)
    doc_bindings = [] of Binding
    
    body = doc.body
    if body
      traverse(body, [] of Int32, doc_bindings)
    end
    
    # Clean HTML for template
    clean_html = body ? body.inner_html : ""
    
    # Parse reactables string to array
    react_vars = reactables.gsub(/[\[\]"']/, "").split(",").map(&.strip).reject(&.empty?)

    # 2. Generate JS
    js = String.build do |s|
        # Template registry must come BEFORE customElements.define so that when
        # connectedCallback fires synchronously during define (for already-connected
        # elements), getTemplate() can find the template.
        s << "if(!window._mochi_templates['#{mochi_cmp_name}']) {\n"
        s << "  const t = document.createElement('template');\n"
        s << "  t.innerHTML = `#{clean_html.gsub("`", "\\`").gsub("${", "\\${")}`;\n"
        s << "  window._mochi_templates['#{mochi_cmp_name}'] = t;\n"

        conditionals.each do |c|
           s << "  const tif#{c.id} = document.createElement('template');\n"
           s << "  tif#{c.id}.innerHTML = `#{c.content.gsub("`", "\\`").gsub("${", "\\${")}`;\n"
           s << "  window._mochi_templates['#{mochi_cmp_name}_if_#{c.id}'] = tif#{c.id};\n"
        end
        each_blocks.each do |e|
           s << "  const teach#{e.id} = document.createElement('template');\n"
           s << "  teach#{e.id}.innerHTML = `#{e.content.gsub("`", "\\`").gsub("${", "\\${")}`;\n"
           s << "  window._mochi_templates['#{mochi_cmp_name}_each_#{e.id}'] = teach#{e.id};\n"
        end
        s << "}\n\n"

        s << "class #{mochi_cmp_name}WebComp extends MochiComponent {\n"
        s << "  constructor() {\n"
        s << "    super();\n"
        s << "    this.element = this;\n"
        s << "    this.rubyComp = Opal.#{mochi_cmp_name}.$new();\n"
        s << "  }\n\n"
        
        # Mount
        s << "  mount(target) {\n"
        s << "    this.rubyComp.$__mochi_mounted(this);\n"
        s << "    const t = MochiComponent.getTemplate('#{mochi_cmp_name}');\n"
        s << "    const r = t.content.cloneNode(true);\n"
        s << "    this.dom_refs = {};\n"
        s << "    this.anchors = {};\n\n"
        
        # Event Delegation
        s << "    this.shadow.addEventListener('click', (event) => {\n"
        s << "      const target = event.target.closest('[onclick]');\n"
        s << "      if (target) {\n"
        s << "        const action = target.getAttribute('onclick').replace(/[{}]/g, '');\n"
        s << "        const methodName = action.split('(')[0].trim();\n"
        s << "        const args = [];\n"
        s << "        let i = 0;\n"
        s << "        while (target.hasAttribute('data-mochi-arg-'+i)) {\n"
        s << "          let rawVal = target.getAttribute('data-mochi-arg-'+i);\n"
        s << "          if (rawVal === '$event') {\n"
        s << "            args.push(event);\n"
        s << "          } else if (rawVal === '$element') {\n"
        s << "            args.push(target);\n"
        s << "          } else {\n"
        s << "          let primVal = Number(rawVal);\n"
        s << "          args.push(Number.isFinite(primVal) ? primVal : rawVal);\n"
        s << "        }\n"
        s << "        i++;\n"
        s << "      }\n"
        s << "      if (target.dataset) {\n"
        s << "        args.push(Object.assign({}, target.dataset));\n"
        s << "      }\n"
        s << "      this.rubyComp['$'+methodName](...args);\n"
        s << "      this.updateAll();\n"
        s << "    }\n"
        s << "    });\n"
        s << "    this.shadow.addEventListener('change', (event) => {\n"
        s << "      const target = event.target.closest('input[onchange], select[onchange], textarea[onchange]');\n"
        s << "      if (target) {\n"
        s << "        const action = target.getAttribute('onchange').replace(/[{}]/g, '');\n"
        s << "        const methodName = action.split('(')[0].trim();\n"
        s << "        const args = [];\n"
        s << "        let i = 0;\n"
        s << "        let hasArgs = false;\n"
        s << "        while (target.hasAttribute('data-mochi-arg-'+i)) {\n"
        s << "          hasArgs = true;\n"
        s << "          let rawVal = target.getAttribute('data-mochi-arg-'+i);\n"
        s << "          if (rawVal === '$event') {\n"
        s << "            args.push(event);\n"
        s << "          } else if (rawVal === '$element') {\n"
        s << "            args.push(target);\n"
        s << "          } else {\n"
        s << "          let primVal = Number(rawVal);\n"
        s << "          args.push(Number.isFinite(primVal) ? primVal : rawVal);\n"
        s << "        }\n"
        s << "        i++;\n"
        s << "      }\n"
        s << "      let dataset = target.dataset ? Object.assign({}, target.dataset) : {};\n"
        s << "      if (hasArgs) {\n"
        s << "        args.push(dataset);\n"
        s << "        this.rubyComp['$'+methodName](...args);\n"
        s << "      } else {\n"
        s << "        let val = target.value;\n"
        s << "        if (!isNaN(val) && val !== '') val = Number(val);\n"
        s << "        this.rubyComp['$'+methodName](event, val, dataset);\n"
        s << "      }\n"
        s << "      this.updateAll();\n"
        s << "    }\n"
        s << "    });\n\n"

        # Paths
        doc_bindings.each_with_index do |b, i|
            path_str = "r"
            b.path.each do |idx|
                path_str += ".childNodes[#{idx}]"
            end
            
            ref_name = "ref_#{i}"
            s << "    const #{ref_name} = #{path_str};\n"
            
            if b.type == :text
               var_name = b.value.gsub(/[{}]/, "")
               # Read template string from the cloned node (contains e.g. "Count123: {count}")
               s << "    const #{ref_name}_tmpl = #{ref_name}.textContent;\n"
               s << "    if(!this.dom_refs['#{var_name}']) this.dom_refs['#{var_name}'] = [];\n"
               s << "    this.dom_refs['#{var_name}'].push({node: #{ref_name}, type: 'text', template: #{ref_name}_tmpl});\n"
               s << "    #{ref_name}.textContent = #{ref_name}_tmpl.replace('{#{var_name}}', this.rubyComp.$get_#{var_name}());\n"
            elsif b.type == :html
               var_name = b.value.gsub(/[{}]/, "")
               # Pure-variable text node: replace with a span so we can use innerHTML for HTML/SVG content
               s << "    const #{ref_name}_span = document.createElement('span');\n"
               s << "    #{ref_name}.parentNode.insertBefore(#{ref_name}_span, #{ref_name});\n"
               s << "    #{ref_name}.parentNode.removeChild(#{ref_name});\n"
               s << "    if(!this.dom_refs['#{var_name}']) this.dom_refs['#{var_name}'] = [];\n"
               s << "    this.dom_refs['#{var_name}'].push({node: #{ref_name}_span, type: 'html'});\n"
               s << "    #{ref_name}_span.innerHTML = this.rubyComp.$get_#{var_name}();\n"
            elsif b.type == :attr
               var_name = b.value.gsub(/[{}]/, "")
               s << "    if(!this.dom_refs['#{var_name}']) this.dom_refs['#{var_name}'] = [];\n"
               s << "    this.dom_refs['#{var_name}'].push({node: #{ref_name}, type: 'attr', name: '#{b.name}'});\n"
               s << "    #{ref_name}.setAttribute('#{b.name}', this.rubyComp.$get_#{var_name}());\n"
            elsif b.type == :anchor
               anchor_id = b.value.gsub(/<!--|-->/, "").strip
               s << "    this.anchors['#{anchor_id}'] = #{ref_name};\n"
            end
        end
        
        # CSS
        s << "    const style = document.createElement('style');\n"
        s << "    style.textContent = `#{css.gsub("`", "\\`").gsub("${", "\\${")}`;\n"
        s << "    this.shadow.appendChild(style);\n"

        s << "    target.appendChild(r);\n"
        s << "    if (this.rubyComp.$mounted) this.rubyComp.$mounted(this);\n"
        s << "    this.updateAll();\n"
        s << "  }\n\n"

        # Update Methods
        react_vars.each do |v|
            s << "  update_#{v}(val) {\n"
            s << "    const refs = this.dom_refs['#{v}'];\n"
            s << "    if (refs) {\n"
            s << "      for (const r of refs) {\n"
            s << "        if (r.type === 'text') r.node.textContent = r.template.replace('{#{v}}', val);\n"
            s << "        else if (r.type === 'html') r.node.innerHTML = val;\n"
            s << "        else if (r.type === 'attr') r.node.setAttribute(r.name, val);\n"
            s << "      }\n"
            s << "    }\n"
            s << "  }\n\n"
        end

        # syncAttributes: legacy compat alias so mounted() hooks that call comp.syncAttributes() still work
        s << "  syncAttributes() { this.updateAll(); }\n\n"

        # updateAll: re-read all reactive vars from Ruby and update DOM, then run derived
        s << "  updateAll() {\n"
        react_vars.each do |v|
            s << "    this.update_#{v}(this.rubyComp.$get_#{v}());\n"
        end
        s << "    this.updateDerived();\n"
        s << "  }\n\n"

        # observedAttributes + attributeChangedCallback for initial HTML attribute propagation
        # Do not expose internal computed attribute conditionals as observed attributes
        public_react_vars = react_vars.reject { |v| v.starts_with?("__mochi_attr_cond_") || v.starts_with?("__mochi_attr_hash_") }
        if public_react_vars.size > 0
            obs_list = public_react_vars.map { |v| "'#{v}'" }.join(", ")
            s << "  static get observedAttributes() { return [#{obs_list}]; }\n\n"
            s << "  attributeChangedCallback(name, oldValue, newValue) {\n"
            s << "    if (oldValue === newValue) return;\n"
            s << "    const setter = '$set_' + name;\n"
            s << "    if (this.rubyComp[setter]) {\n"
            s << "      let val = newValue;\n"
            s << "      if (!isNaN(val) && val !== '' && val !== null) val = Number(val);\n"
            s << "      this.rubyComp[setter](val);\n"
            s << "    }\n"
            s << "    this.updateAll();\n"
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
        s << "customElements.define('#{tag_name}', #{mochi_cmp_name}WebComp);\n"
    end
    
    WebComponent.new("#{mochi_cmp_name}WebComp", js)
  end
  
  def traverse(node : Lexbor::Node, path : Array(Int32), bindings : Array(Binding))
    tag = node.tag_name
    
    if tag == "_text"
        text = node.tag_text
        if text =~ /\{([^}]+)\}/
             var_name = $1
             # Pure variable nodes (e.g. "\n  {rendered_svg}\n") use innerHTML to allow HTML/SVG content
             binding_type = text.strip == "{#{var_name}}" ? :html : :text
             bindings << Binding.new(path, binding_type, "{#{var_name}}")
        end
    elsif tag == "_em_comment"
        text = node.tag_text
        if text.includes?("if-anchor") || text.includes?("each-anchor")
             bindings << Binding.new(path, :anchor, text)
        end
    else
        if node.attributes
          remove_attrs = [] of String
          node.attributes.each do |k, v|
             if k.starts_with?("bind:")
                attr_name = k[5..-1]
                var_name = v.gsub(/[{}]/, "")
                bindings << Binding.new(path, :attr, "{#{var_name}}", attr_name)
                remove_attrs << k
             elsif k.starts_with?("on")
                # Event handler attribute — leave in HTML for event delegation, don't treat as reactive binding
             elsif v =~ /\{([^}]+)\}/
                var_name = $1
                bindings << Binding.new(path, :attr, "{#{var_name}}", k)
                remove_attrs << k
             end
          end
          remove_attrs.each { |k| node.attribute_remove(k) }
        end
        
        if node.children
           node.children.each_with_index do |child, i|
               traverse(child, path + [i], bindings)
           end
        end
    end
  end

end
