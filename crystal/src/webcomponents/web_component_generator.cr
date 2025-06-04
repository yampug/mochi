require "./web_component"

class WebComponentGenerator

  
  def initialize
  end
  
  # tag_name = elName
  def generate(
    mochi_cmp_name : String, 
    tag_name : String, 
    css : String, 
    html : String, 
    reactables : String, 
    bindings : Hash(String, String)) : WebComponent
  
    web_cmp_name = "#{mochi_cmp_name}WebComp"
    reactables_arr_anme = "reactablesArr#{web_cmp_name}"
    
    on_click_placeholder = "__on_click_placeholder__"
    on_change_placeholder = "__on_change_placeholder__"
    
    bindings_code = ""
    bindings.each do |key, value|
      puts "key:#{key}, val:#{value}"
    
      bindings_code += "let bindElements = this.shadow.querySelectorAll('[#{value}]');\n"
      bindings_code += "if (bindElements) {\n"
      bindings_code += "  for (let i = 0; i < bindElements.length; i++) {\n"
      bindings_code += "    const observer = new MutationObserver((mutationsList, observer) => {\n"
      bindings_code += "      for (const mutation of mutationsList) {\n"
      bindings_code += "        if (mutation.type === 'attributes') {\n"
      bindings_code += "          let newValue = mutation.target.getAttribute(mutation.attributeName);\n"
      bindings_code += "          this.attributeChangedCallback('#{key}', null, newValue);\n"
      bindings_code += "        }\n"
      bindings_code += "      }\n"
      bindings_code += "    });\n"
      bindings_code += "    observer.observe(bindElements[i], {\n"
      bindings_code += "      attributes: true,\n"
      bindings_code += "      childList: false,\n"
      bindings_code += "      subtree: false,\n"
      bindings_code += "      characterData: false,\n"
      bindings_code += "      attributeOldValue: false\n"
      bindings_code += "    });\n"
      bindings_code += "  }\n"
      bindings_code += "}\n"
      
    end
    
    js_code = <<-TEXT
      let #{reactables_arr_anme} = #{reactables};
      
      class #{mochi_cmp_name} extends HTMLElement {
        constructor() {
          super();
          this.rubyComp = Opal.#{mochi_cmp_name}.$new();
          this.paintCount = 0;
        }
        
        connectedCallback() {
          this.rubyComp.$mounted();
          this.shadow = this.attachShadow({ mode: "open" });
          this.render();
        }
        
        syncAttributes() {
          // sync attributes (method call may have altered them)
          console.log("syncing attributes")
          for (let i = 0; i < #{reactables_arr_anme}.length; i++) {
              this.setAttribute(#{reactables_arr_anme}[i], this.rubyComp["$get_" + #{reactables_arr_anme}[i]]());
          }
        }
        
        render() {
          // TODO check if vars actually changed (optimization)
          let html = `
            #{html}
          `;
          
          for (let i = 0; i < #{reactables_arr_anme}.length; i++) {
              console.log(#{reactables_arr_anme}[i]);
              html = html.replaceAll("{" + #{reactables_arr_anme}[i] + "}", this.rubyComp["$get_" + #{reactables_arr_anme}[i]]());
          }
          
          if (this.shadow) {
              this.shadow.innerHTML = html;

              const style = document.createElement("style");
              style.textContent = `
                  #{css}
              `;
              this.shadow.appendChild(style);
              if (this.paintCount === 0) {
                  // listen to click events
                  this.shadow.addEventListener('click', (event) => {
                    const clickedElement = event.target;
                    const actionTarget = clickedElement.closest('#{on_click_placeholder}');
                    if (actionTarget) {
                      let actionValue = actionTarget.getAttribute('on:click');
                      // remove curly braces
                      let trimmedActionVal = actionValue.substring(1, actionValue.length - 1);

                      // basically call the method Opal.compInstance.new.method()
                      this.rubyComp["$"+trimmedActionVal]()
                      this.syncAttributes();
                      this.render();
                    }
                  });

                  // listen to change events
                  let matches = this.shadow.querySelectorAll("#{on_change_placeholder}")
                  if (matches) {
                      for (let i = 0; i < matches.length; i++) {
                          matches[i].addEventListener("change", (event) => {

                                let actionValue = event.target.getAttribute('on:change');
                              // remove curly braces
                              let trimmedActionVal = actionValue.substring(1, actionValue.length - 1);
                              let value = event.target.value;
                              // auto-convert value to number if numeric
                                const primValue = Number(value);
                                if (Number.isFinite(primValue)) {
                                  this.rubyComp["$"+trimmedActionVal](event, primValue);
                                } else {
                                  this.rubyComp["$"+trimmedActionVal](event, value);
                                }


                              this.syncAttributes();
                              this.render();
                          });
                      }
                  }
              }

              #{bindings_code}
              this.paintCount = this.paintCount + 1;
          }
        }
      
        disconnectedCallback() {
            this.rubyComp.$unmounted();
        }

        static get observedAttributes() {
            return #{reactables};
        }
        
        attributeChangedCallback(name, oldValue, newValue) {
          console.log("Attribute " + name + " has changed from " + oldValue + " to " + newValue + "");
          // TODO
          // TODO react to attributes changing
          if (oldValue === newValue) {
              return;
          }
          try {
              let currentValue = this.rubyComp["$get_" + name]();
              if (typeof currentValue === "number") {
                  // assign as number
                  this.rubyComp["$set_" + name](Number(newValue));
              } else {
                  // assign as string
                  this.rubyComp["$set_" + name](newValue);
              }
              this.render();
          } catch (e) {
              console.error("Component render failed", e);
          }
        }
      }
      customElements.define("#{tag_name}", #{mochi_cmp_name});
    TEXT
    
    # heredocs syntax removes backslashes, so need to be added like this
    js_code = js_code
      .gsub(on_click_placeholder, "[on\\\\:click]")
      .gsub(on_change_placeholder, "input[on\\\\:change]")
    
    puts js_code
    return WebComponent.new(name = web_cmp_name, js_code)
  end
end