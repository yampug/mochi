require "./web_component"
require "./web_component_placeholder"
require "../html/conditional_processor"

class WebComponentGenerator

  def initialize
  end

  def self.generate_bindings_code(bindings : Hash(String, String)) : String
    result = ""
    bindings.each do |key, value|
      #puts "key:#{key}, val:#{value}"

      tmp = <<-TEXT
        let bindElements = this.shadow.querySelectorAll('[#{value}]');
        if (bindElements) {
          for (let i = 0; i < bindElements.length; i++) {
            const observer = new MutationObserver((mutationsList, observer) => {
              for (const mutation of mutationsList) {
                if (mutation.type === 'attributes') {
                  let newValue = mutation.target.getAttribute(mutation.attributeName);
                  this.attributeChangedCallback('#{key}', null, newValue);
                }
              }
            });
            observer.observe(bindElements[i], {
              attributes: true,
              childList: false,
              subtree: false,
              characterData: false,
              attributeOldValue: false
            });
          }
        }
      TEXT
      result += tmp + "\n"
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

    puts conditionals

    web_cmp_name = ""
    js_code = ""

    time = Time.measure do
      web_cmp_name = "#{mochi_cmp_name}WebComp"
      reactables_arr_anme = "reactablesArr#{web_cmp_name}"

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
            #{WebComponentGenerator.generate_render_code(
                reactables_arr_anme,
                conditionals,
                html,
                css,
                bindings_code
            )}
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
        .gsub(WebComponentPlaceholder::OnClick.string_value, "[on\\\\:click]")
        .gsub(WebComponentPlaceholder::OnChange.string_value, "input[on\\\\:change]")

      #puts js_code
    end
    puts "> WebComponent '#{web_cmp_name}' generation took #{time.total_milliseconds.to_i}ms"
    return WebComponent.new(name = web_cmp_name, js_code)
  end

  def self.generate_render_code(
    reactables_arr_anme : String,
    conditionals : Array(ConditionalBlock),
    html : String,
    css : String,
    bindings_code : String) : String


    result = <<-TEXT
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
        #{WebComponentGenerator.generate_conditional_evaluation_code(conditionals)}

        const style = document.createElement("style");
        style.textContent = `
            #{css}
        `;
        this.shadow.appendChild(style);
        if (this.paintCount === 0) {
            // listen to click events
            this.shadow.addEventListener('click', (event) => {
              const clickedElement = event.target;
              const actionTarget = clickedElement.closest('#{WebComponentPlaceholder::OnClick.string_value}');
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
            let matches = this.shadow.querySelectorAll("#{WebComponentPlaceholder::OnChange.string_value}")
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
    TEXT
    return result
  end

  def self.generate_conditional_evaluation_code(conditionals : Array(ConditionalBlock)) : String
    return "" if conditionals.empty?

    result = <<-TEXT
      let conditionalElements = this.shadow.querySelectorAll('mochi-if');
      for (let condEl of conditionalElements) {
        let condId = parseInt(condEl.getAttribute('data-cond-id'));
        let result = this.evaluateCondition(condId);
        condEl.style.display = result ? '' : 'none';
      }
    TEXT

    result
  end
end
