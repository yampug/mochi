require "./web_component"
require "../html/conditional_processor"

class WebComponentGenerator

  def initialize
  end

  def self.generate_bindings_code(bindings : Hash(String, String)) : String
    result = ""
    bindings.each do |key, value|
      #puts "key:#{key}, val:#{value}"
      result += "let bindElements = this.shadow.querySelectorAll('[#{value}]');\n"
      result += "if (bindElements) {\n"
      result += "  for (let i = 0; i < bindElements.length; i++) {\n"
      result += "    const observer = new MutationObserver((mutationsList, observer) => {\n"
      result += "      for (const mutation of mutationsList) {\n"
      result += "        if (mutation.type === 'attributes') {\n"
      result += "          let newValue = mutation.target.getAttribute(mutation.attributeName);\n"
      result += "          this.attributeChangedCallback('#{key}', null, newValue);\n"
      result += "        }\n"
      result += "      }\n"
      result += "    });\n"
      result += "    observer.observe(bindElements[i], {\n"
      result += "      attributes: true,\n"
      result += "      childList: false,\n"
      result += "      subtree: false,\n"
      result += "      characterData: false,\n"
      result += "      attributeOldValue: false\n"
      result += "    });\n"
      result += "  }\n"
      result += "}\n"
    end
    return result
  end

  def self.generate_attribute_changed_callback() : String
    result = <<-TEXT
      attributeChangedCallback(name, oldValue, newValue) {
          il.info("Attribute " + name + " has changed from " + oldValue + " to " + newValue + "");
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
              il.error("Component render failed", e);
          }
        }

    TEXT
    return result
  end

  # tag_name = elName
  def generate(
    mochi_cmp_name : String,
    tag_name : String,
    css : String,
    html : String,
    reactables : String,
    bindings : Hash(String, String),
    conditionals : Array(ConditionalBlock) = [] of ConditionalBlock) : WebComponent

    web_cmp_name = ""
    js_code = ""

    time = Time.measure do
      web_cmp_name = "#{mochi_cmp_name}WebComp"
      reactables_arr_anme = "reactablesArr#{web_cmp_name}"

      on_click_placeholder = "__on_click_placeholder__"
      on_change_placeholder = "__on_change_placeholder__"

      bindings_code = WebComponentGenerator.generate_bindings_code(bindings)

      js_code = <<-TEXT
        let #{reactables_arr_anme} = #{reactables};

        class #{mochi_cmp_name} extends HTMLElement {
          constructor() {
            super();
            this.rubyComp = Opal.#{mochi_cmp_name}.$new();
            this.paintCount = 0;
            this.element = this;
          }

          connectedCallback() {
            this.shadow = this.attachShadow({ mode: "open" });
            this.render();
            this.rubyComp.$mounted(this.shadow, this);
          }

          syncAttributes() {
            // sync attributes (method call may have altered them)
            il.debug("syncing attributes")
            for (let i = 0; i < #{reactables_arr_anme}.length; i++) {
                this.setAttribute(#{reactables_arr_anme}[i], this.rubyComp["$get_" + #{reactables_arr_anme}[i]]());
            }
          }

          evaluateCondition(condId) {
            // Call the pre-compiled Ruby method for this conditional
            try {
              let methodName = `$__mochi_cond_${condId}`;
              let result = this.rubyComp[methodName]();

              // Convert Ruby truthy/falsy to JavaScript boolean
              // In Opal: false and nil are falsy, everything else is truthy
              return result !== false && result !== Opal.nil;
            } catch (e) {
              il.error('Error evaluating conditional method ' + condId, e);
              return false;
            }
          }

          render() {
            // TODO check if vars actually changed (optimization)
            let html = `
              #{html}
            `;

            for (let i = 0; i < #{reactables_arr_anme}.length; i++) {
                il.info(#{reactables_arr_anme}[i]);
                html = html.replaceAll("{" + #{reactables_arr_anme}[i] + "}", this.rubyComp["$get_" + #{reactables_arr_anme}[i]]());
            }

            if (this.shadow) {
                this.shadow.innerHTML = html;

                // Evaluate conditional blocks
                #{generate_conditional_evaluation_code(conditionals)}

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

          #{WebComponentGenerator.generate_attribute_changed_callback}
        }
        customElements.define("#{tag_name}", #{mochi_cmp_name});
      TEXT

      # heredocs syntax removes backslashes, so need to be added like this
      js_code = js_code
        .gsub(on_click_placeholder, "[on\\\\:click]")
        .gsub(on_change_placeholder, "input[on\\\\:change]")

      #puts js_code
    end
    puts "> WebComponent '#{web_cmp_name}' generation took #{time.total_milliseconds.to_i}ms"
    return WebComponent.new(name = web_cmp_name, js_code)
  end

  # Generate JavaScript code to evaluate conditional blocks at runtime
  private def generate_conditional_evaluation_code(conditionals : Array(ConditionalBlock)) : String
    return "" if conditionals.empty?

    code = ""
    code += "let conditionalElements = this.shadow.querySelectorAll('mochi-if');\n"
    code += "                for (let condEl of conditionalElements) {\n"
    code += "                  let condId = parseInt(condEl.getAttribute('data-cond-id'));\n"
    code += "                  let result = this.evaluateCondition(condId);\n"
    code += "                  condEl.style.display = result ? '' : 'none';\n"
    code += "                }\n"

    code
  end
end
