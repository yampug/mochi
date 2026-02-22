require "./web_component"
require "./web_component_placeholder"
require "../html/conditional_processor"
require "../html/each_processor"

class LegacyComponentGenerator

  def initialize
  end

  def self.generate_bindings_code(bindings : Hash(String, String)) : String
    result = ""
    i = 0
    bindings.each do |key, value|
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

  def self.generate_bindings_update_code(bindings : Hash(String, String)) : String
    return "" if bindings.empty?
    result = ""
    bindings.each do |key, attr_name|
      result += <<-TEXT
        {
          let _bval = this.rubyComp["$get_#{key}"]();
          let _bels = this.shadow.querySelectorAll('[#{attr_name}]');
          for (let _bel of _bels) _bel.setAttribute(#{attr_name.inspect}, _bval);
        }
      TEXT
    end
    result
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
          if (typeof newValue === 'string' && /^\\{[^}]+\\}$/.test(newValue)) {
              return;
          }
          try {
              let currentValue = this.rubyComp["$get_" + name]();
              let alreadyMatches = typeof currentValue === "number"
                ? currentValue === Number(newValue)
                : String(currentValue) === String(newValue);
              if (alreadyMatches) return;
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
      reactables_arr_name = "reactablesArr#{web_cmp_name}"

      bindings_code = LegacyComponentGenerator.generate_bindings_code(bindings)
      bindings_update_code = LegacyComponentGenerator.generate_bindings_update_code(bindings)

      js_code = <<-TEXT
        let #{reactables_arr_name} = #{reactables};

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
            this.render();
          }

          syncAttributes() {
            il.debug("syncing attributes")
            for (let i = 0; i < #{reactables_arr_name}.length; i++) {
                this.setAttribute(#{reactables_arr_name}[i], this.rubyComp["$get_" + #{reactables_arr_name}[i]]());
            }
          }

          evaluateCondition(condId) {
            try {
              let result = this.rubyComp[`$__mochi_cond_${condId}`]();
              return result !== false && result !== Opal.nil;
            } catch (e) {
              il.error('Error evaluating conditional method ' + condId, e);
              return false;
            }
          }

          evaluateEachLoop(loopId) {
            try {
              let items = this.rubyComp[`$__mochi_each_${loopId}_items`]();
              if (items && items.$to_a) items = items.$to_a();
              return items || [];
            } catch (e) {
              il.error('Error evaluating each loop method ' + loopId, e);
              return [];
            }
          }

          getEachLoopKey(loopId, item, index) {
            try {
              return this.rubyComp[`$__mochi_each_${loopId}_key`](item, index);
            } catch (e) {
              return index;
            }
          }

          _computeLIS(arr) {
            if (!arr.length) return [];
            let tails = [], preds = new Array(arr.length).fill(-1);
            for (let i = 0; i < arr.length; i++) {
              let lo = 0, hi = tails.length;
              while (lo < hi) { let mid = lo + hi >> 1; arr[tails[mid]] < arr[i] ? lo = mid + 1 : hi = mid; }
              tails[lo] = i;
              if (lo > 0) preds[i] = tails[lo - 1];
            }
            let res = [], i = tails[tails.length - 1];
            while (i !== undefined && i !== -1) { res.unshift(i); i = preds[i]; }
            return res;
          }

          _substituteItemVars(root, item, index) {
            let walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null);
            let node;
            while ((node = walker.nextNode())) {
              if (node.data.includes('{index}')) {
                node.data = node.data.replace(/\\{index\\}/g, index);
              }
              node.data = node.data.replace(/\\{item\\.(\\w+)\\}/g, (_, prop) => {
                try {
                  if (typeof item['$' + prop] === 'function') return item['$' + prop]();
                  if (item[prop] !== undefined) return item[prop];
                } catch(e) {}
                return '{item.' + prop + '}';
              });
            }
          }

          _reconcileEachBlock(blockId) {
            let rawItems = this.evaluateEachLoop(blockId);
            let newItems = rawItems || [];
            let oldStates = this._eachItems[blockId];
            let anchor = this._eachAnchors[blockId];
            if (!anchor) return;

            let oldKeyMap = new Map(oldStates.map(s => [s.key, s]));
            let newStates = newItems.map((item, i) => ({
              key: this.getEachLoopKey(blockId, item, i),
              item,
              index: i
            }));
            let newKeySet = new Set(newStates.map(s => s.key));

            for (let [key, old] of oldKeyMap) {
              if (!newKeySet.has(key)) {
                for (let node of old.nodes) node.parentNode && node.parentNode.removeChild(node);
              }
            }

            let surviving = oldStates.filter(s => newKeySet.has(s.key));
            let keyToNewIdx = new Map(newStates.map((s, i) => [s.key, i]));
            let survivingNewIndices = surviving.map(s => keyToNewIdx.get(s.key));
            let lisResult = this._computeLIS(survivingNewIndices);
            let lisKeys = new Set(lisResult.map(i => surviving[i].key));

            let cursor = anchor;
            let nextItemStates = [];

            for (let {key, item, index} of newStates) {
              if (oldKeyMap.has(key)) {
                let old = oldKeyMap.get(key);
                if (!lisKeys.has(key)) {
                  for (let node of old.nodes) {
                    cursor.parentNode.insertBefore(node, cursor.nextSibling);
                    cursor = node;
                  }
                } else {
                  cursor = old.nodes[old.nodes.length - 1];
                }
                nextItemStates.push({key, nodes: old.nodes});
              } else {
                let frag = this._eachTemplates[blockId].content.cloneNode(true);
                this._substituteItemVars(frag, item, index);
                let nodes = Array.from(frag.childNodes);
                cursor.parentNode.insertBefore(frag, cursor.nextSibling);
                cursor = nodes[nodes.length - 1];
                nextItemStates.push({key, nodes});
              }
            }

            this._eachItems[blockId] = nextItemStates;
          }

          render() {
            #{LegacyComponentGenerator.generate_render_code(
                reactables_arr_name,
                conditionals,
                each_blocks,
                html,
                css,
                bindings_code,
                bindings_update_code
            )}
          }

          disconnectedCallback() {
              this.rubyComp.$unmounted();
          }

          static get observedAttributes() {
              return #{reactables};
          }

          #{LegacyComponentGenerator.generate_attribute_changed_callback}
        }
        customElements.define("#{tag_name}", #{mochi_cmp_name});
      TEXT

      js_code = js_code
        .gsub(WebComponentPlaceholder::OnClick.string_value, "[on\\\\:click]")
        .gsub(WebComponentPlaceholder::OnChange.string_value, "input[on\\\\:change]")
    end
    puts "> WebComponent '#{web_cmp_name}' generation took #{time.total_milliseconds.to_i}ms"
    return WebComponent.new(name = web_cmp_name, js_code)
  end

  def self.generate_render_code(
    reactables_arr_name : String,
    conditionals : Array(ConditionalBlock),
    each_blocks : Array(EachBlock),
    html : String,
    css : String,
    bindings_code : String,
    bindings_update_code : String = "") : String

    cond_init = generate_conditional_init_code(conditionals)
    cond_update = generate_conditional_update_code(conditionals)
    each_init = generate_each_init_code(each_blocks)
    each_update = generate_each_update_code(each_blocks)

    result = <<-TEXT
    if (!this.shadow) return;
    if (this.paintCount === 0) {
        this.shadow.innerHTML = `
          #{html}
        `;

        this._rnCache = {};
        this._attrCache = {};
        {
          let _w = document.createTreeWalker(this.shadow, NodeFilter.SHOW_TEXT, null);
          let _n;
          while ((_n = _w.nextNode())) {
            for (let _r of #{reactables_arr_name}) {
              if (_n.data.includes('{' + _r + '}')) {
                if (!this._rnCache[_r]) this._rnCache[_r] = [];
                this._rnCache[_r].push({node: _n, t: _n.data, container: null});
              }
            }
          }
          let _all = this.shadow.querySelectorAll('*');
          for (let _el of _all) {
            for (let _r of #{reactables_arr_name}) {
              for (let _a of _el.attributes) {
                if (_a.value.includes('{' + _r + '}')) {
                  if (!this._attrCache[_r]) this._attrCache[_r] = [];
                  this._attrCache[_r].push({el: _el, attr: _a.name, t: _a.value});
                }
              }
            }
          }
        }

        this._ifTemplates = {}; this._ifAnchors = {}; this._ifRendered = {};
        #{cond_init}

        this._eachTemplates = {}; this._eachAnchors = {}; this._eachItems = {};
        #{each_init}

        this.shadow.addEventListener('click', (event) => {
          const clickedElement = event.target;
          const actionTarget = clickedElement.closest('#{WebComponentPlaceholder::OnClick.string_value}');
          if (actionTarget) {
            let actionValue = actionTarget.getAttribute('on:click');
            let trimmedActionVal = actionValue.substring(1, actionValue.length - 1);
            this.rubyComp["$"+trimmedActionVal]();
            this.syncAttributes();
            this.render();
          }
        });

        let _changeTargets = this.shadow.querySelectorAll("#{WebComponentPlaceholder::OnChange.string_value}");
        if (_changeTargets) {
          for (let _i = 0; _i < _changeTargets.length; _i++) {
            _changeTargets[_i].addEventListener("change", (event) => {
              let actionValue = event.target.getAttribute('on:change');
              let trimmedActionVal = actionValue.substring(1, actionValue.length - 1);
              let value = event.target.value;
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

        #{bindings_code}

        const style = document.createElement("style");
        style.textContent = `
            #{css}
        `;
        this.shadow.appendChild(style);
    }

    for (let _r of #{reactables_arr_name}) {
        let _val = this.rubyComp["$get_" + _r]();
        let _entries = this._rnCache[_r];
        if (_entries) {
          for (let e of _entries) {
            let _s = String(_val);
            if (_s.includes('<')) {
              if (!e.container) {
                let _sp = document.createElement('span');
                e.node.parentNode.replaceChild(_sp, e.node);
                e.container = _sp;
              }
              e.container.innerHTML = _s;
            } else if (e.container) {
              let _tn = document.createTextNode(e.t.replace('{' + _r + '}', _s));
              e.container.parentNode.replaceChild(_tn, e.container);
              e.node = _tn;
              e.container = null;
            } else {
              e.node.data = e.t.replace('{' + _r + '}', _val);
            }
          }
        }
        let _aentries = this._attrCache[_r];
        if (_aentries) {
          for (let {el, attr, t} of _aentries) {
            el.setAttribute(attr, t.replace('{' + _r + '}', _val));
          }
        }
    }

    #{bindings_update_code}

    #{each_update}

    #{cond_update}

    this.paintCount++;
    TEXT
    return result
  end

  def self.generate_conditional_init_code(conditionals : Array(ConditionalBlock)) : String
    return "" if conditionals.empty?

    result = ""
    conditionals.each do |block|
      result += <<-TEXT
        {
          const _t = document.createElement('template');
          _t.innerHTML = #{block.content.inspect};
          this._ifTemplates[#{block.id}] = _t;
          let _it = document.createNodeIterator(this.shadow, NodeFilter.SHOW_COMMENT, {
            acceptNode: function(node) {
              return node.nodeValue === 'if-anchor-#{block.id}' ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP;
            }
          });
          this._ifAnchors[#{block.id}] = _it.nextNode();
          this._ifRendered[#{block.id}] = null;
        }
      TEXT
    end
    result
  end

  def self.generate_conditional_update_code(conditionals : Array(ConditionalBlock)) : String
    return "" if conditionals.empty?

    result = ""
    conditionals.each do |block|
      result += <<-TEXT
        {
          let _anchor = this._ifAnchors[#{block.id}];
          if (_anchor) {
            let _show = this.evaluateCondition(#{block.id});
            if (_show && !this._ifRendered[#{block.id}]) {
              let _clone = this._ifTemplates[#{block.id}].content.cloneNode(true);
              this._ifRendered[#{block.id}] = Array.from(_clone.childNodes);
              _anchor.parentNode.insertBefore(_clone, _anchor.nextSibling);
            } else if (!_show && this._ifRendered[#{block.id}]) {
              this._ifRendered[#{block.id}].forEach(n => n.parentNode && n.parentNode.removeChild(n));
              this._ifRendered[#{block.id}] = null;
            }
          }
        }
      TEXT
    end
    result
  end

  def self.generate_each_init_code(each_blocks : Array(EachBlock)) : String
    return "" if each_blocks.empty?

    result = ""
    each_blocks.each do |block|
      result += <<-TEXT
        {
          const _t = document.createElement('template');
          _t.innerHTML = #{block.content.inspect};
          this._eachTemplates[#{block.id}] = _t;
          let _it = document.createNodeIterator(this.shadow, NodeFilter.SHOW_COMMENT, {
            acceptNode: function(node) {
              return node.nodeValue === 'each-anchor-#{block.id}' ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP;
            }
          });
          this._eachAnchors[#{block.id}] = _it.nextNode();
          this._eachItems[#{block.id}] = [];
          this._reconcileEachBlock(#{block.id});
        }
      TEXT
    end
    result
  end

  def self.generate_each_update_code(each_blocks : Array(EachBlock)) : String
    return "" if each_blocks.empty?

    result = ""
    each_blocks.each do |block|
      result += "this._reconcileEachBlock(#{block.id});\n"
    end
    result
  end

end
