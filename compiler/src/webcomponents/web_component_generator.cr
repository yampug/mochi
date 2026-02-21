require "./web_component"
require "./web_component_placeholder"
require "../html/conditional_processor"
require "../html/each_processor"

class WebComponentGenerator

  def initialize
  end

  def self.generate_bindings_code(bindings : Hash(String, String)) : String
    result = ""
    i = 0
    bindings.each do |key, value|
      #puts "key:#{key}, val:#{value}"

      bind_el_obj = "bindElements#{i}"
      tmp = <<-TEXT
        let #{bind_el_obj} = this.shadow.querySelectorAll('[#{value}]');
        if (#{bind_el_obj}) {
          for (let i = 0; i < #{bind_el_obj}.length; i++) {
            const observer = new MutationObserver((mutationsList, observer) => {
              for (const mutation of mutationsList) {
                if (mutation.type === 'attributes') {
                  let newValue = mutation.target.getAttribute(mutation.attributeName);
                  this.attributeChangedCallback('#{key}', null, newValue);
                }
              }
            });
            observer.observe(#{bind_el_obj}[i], {
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
      i += 1
    end
    return result
  end

  def self.generate_attribute_changed_callback() : String
    result = <<-TEXT
      attributeChangedCallback(name, oldValue, newValue) {
          il.info(`Attribute ${name} has changed from '${oldValue}' to '${newValue}' (${typeof newValue})`);

          // TODO tests
          // TODO react to attributes changing
          if (oldValue === newValue) {
              return;
          }
          try {
              let currentValue = this.rubyComp["$get_" + name]();
              if (typeof currentValue === "number") {
                  // assign as number
                  this.rubyComp["$set_" + name](Number(newValue));
              } else if (newValue === "true" || newValue === "false") {
                  // assing as boolean
                  this.rubyComp["$set_" + name](Boolean(newValue));
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
    conditionals : Array(ConditionalBlock) = [] of ConditionalBlock,
    each_blocks : Array(EachBlock) = [] of EachBlock) : WebComponent

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

          evaluateEachLoop(loopId) {
            // Call the pre-compiled Ruby method to get items array
            try {
              let itemsMethodName = `$__mochi_each_${loopId}_items`;
              let items = this.rubyComp[itemsMethodName]();

              // Convert Opal array to JavaScript array if needed
              if (items && items.$to_a) {
                items = items.$to_a();
              }

              return items || [];
            } catch (e) {
              il.error('Error evaluating each loop method ' + loopId, e);
              return [];
            }
          }

          getEachLoopKey(loopId, item, index) {
            // Call the pre-compiled Ruby method to get the key for an item
            let keyMethodName = "";
            try {
              keyMethodName = `$__mochi_each_${loopId}_key`;
              let key = this.rubyComp[keyMethodName](item, index);
              return key;
            } catch (e) {
              il.error('Error getting key "' + keyMethodName + '" for loop ' + loopId, e);
              return index;
            }
          }

          render() {
            #{WebComponentGenerator.generate_render_code(
                reactables_arr_anme,
                conditionals,
                each_blocks,
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
    each_blocks : Array(EachBlock),
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

        // Evaluate each loop blocks
        #{WebComponentGenerator.generate_each_evaluation_code(each_blocks)}

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

    result = ""
    conditionals.each do |block|
      result += <<-TEXT
        if (!this._frag_templates) this._frag_templates = {};
        if (!this._frag_templates[#{block.id}]) {
          const t = document.createElement('template');
          t.innerHTML = #{block.content.inspect};
          this._frag_templates[#{block.id}] = t;
        }
        
        {
          let it = document.createNodeIterator(this.shadow, NodeFilter.SHOW_COMMENT, {
            acceptNode: function(node) {
              return node.nodeValue === 'if-anchor-#{block.id}' ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP;
            }
          });
          
          let anchor = it.nextNode();
          if (anchor) {
             let result = this.evaluateCondition(#{block.id});
             if (result) {
                let clone = this._frag_templates[#{block.id}].content.cloneNode(true);
                anchor.parentNode.insertBefore(clone, anchor.nextSibling);
             }
          }
        }
      TEXT
    end

    result
  end

  def self.generate_each_evaluation_code(each_blocks : Array(EachBlock)) : String
    return "" if each_blocks.empty?

    result = <<-TEXT
      // Initialize template storage on first render
      if (!this.eachTemplates) {
        this.eachTemplates = {};
      }

      let eachElements = this.shadow.querySelectorAll('mochi-each');
      for (let eachEl of eachElements) {
        let loopId = parseInt(eachEl.getAttribute('data-loop-id'));

        // Store template on first access
        if (!this.eachTemplates[loopId]) {
          this.eachTemplates[loopId] = eachEl.innerHTML;
        }

        let template = this.eachTemplates[loopId];
        let items = this.evaluateEachLoop(loopId);

        // Clear current content
        eachEl.innerHTML = '';

        // Render each item
        for (let i = 0; i < items.length; i++) {
          let item = items[i];
          let key = this.getEachLoopKey(loopId, item, i);

          // Clone template for this item
          let itemHtml = template;

          // Replace item property references like {item.name}, {item.id}, etc.
          // We call Ruby methods on the item to get property values
          let propertyPattern = /\\{item\\.(\\w+)\\}/g;
          itemHtml = itemHtml.replace(propertyPattern, (match, propName) => {
            try {
              // Call Ruby getter method on the item
              let methodName = '$' + propName;
              if (item[methodName]) {
                return item[methodName]();
              }
              return match; // Keep original if method not found
            } catch (e) {
              il.error('Error accessing property ' + propName + ' on item', e);
              return match;
            }
          });

          // Replace {index} references
          itemHtml = itemHtml.replace(/\\{index\\}/g, i);

          // Create wrapper for this item
          let itemWrapper = document.createElement('div');
          itemWrapper.setAttribute('data-each-item', '');
          itemWrapper.setAttribute('data-key', key);
          itemWrapper.innerHTML = itemHtml;

          eachEl.appendChild(itemWrapper);
        }
      }
    TEXT

    result
  end
end
