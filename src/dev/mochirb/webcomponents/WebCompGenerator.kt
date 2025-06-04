package dev.mochirb.webcomponents

object WebCompGenerator {

    fun generate(
        mochiCompName: String,
        elName: String,
        css: String,
        html: String,
        reactables: String,
        bindings: Map<String, String>): WebComp {

        println("reactables:$reactables")

        val bindingCode = StringBuilder()
        bindings.forEach { (key, value) ->
            bindingCode.appendLine("let bindElements = this.shadow.querySelectorAll(\"[$value]\")")
            bindingCode.appendLine("if (bindElements) {")
            bindingCode.appendLine("for (let i = 0; i < bindElements.length; i++) {")
            //bindingCode.appendLine("console.log(bindElements[i]);")
            bindingCode.appendLine("""
                const observer = new MutationObserver((mutationsList, observer) => {
        for (const mutation of mutationsList) {
          if (mutation.type === 'attributes') {
            let newValue = mutation.target.getAttribute(mutation.attributeName);
          //console.log(mutation.target.getAttribute(mutation.attributeName));
//                    const currentValue = parseInt(trackedElement.getAttribute('pfcount'), 10);

            //console.log("Attribute '"+mutation.attributeName+" was modified.");
            this.attributeChangedCallback("$key", null, newValue)
          }
        }
      });
      observer.observe(bindElements[i], {
        attributes: true,
        childList: false,
        subtree: false, // if you want to listen to changes within children of the element with pfcount
        characterData: false,
        attributeOldValue: false // if you need the old value of an attribute
      });
            """.trimIndent())
            bindingCode.appendLine("}")
            bindingCode.appendLine("}")
        }

        val webCompName = "${mochiCompName}WebComp"
        val reactablesArrName = "reactablesArr${webCompName}"
        val jsCode = """

            let ${reactablesArrName} = ${reactables};

            class ${webCompName} extends HTMLElement {

                constructor() {
                    super();
                    this.rubyComp = Opal.${mochiCompName}.${'$'}new();
                    this.paintCount = 0;
                }

                connectedCallback() {
                    this.rubyComp.${'$'}mounted();
                    this.shadow = this.attachShadow({ mode: "open" });
                    this.render();
                }

                syncAttributes() {
                    // sync attributes (method call may have altered them)
                    for (let i = 0; i < ${reactablesArrName}.length; i++) {
                        this.setAttribute(${reactablesArrName}[i], this.rubyComp["${'$'}get_" + ${reactablesArrName}[i]]());
                    }
                }

                render() {
                    // TODO check if vars actually changed
                    let html = `
                        ${html}
                    `;

                    for (let i = 0; i < ${reactablesArrName}.length; i++) {
                       // console.log(${reactablesArrName}[i]);
                       html = html.replaceAll("{" + ${reactablesArrName}[i] + "}", this.rubyComp["${'$'}get_" + ${reactablesArrName}[i]]());
                    }

                    if (this.shadow) {
                        this.shadow.innerHTML = html;

                        const style = document.createElement("style");
                        style.textContent = `
                            ${css}
                        `;
                        this.shadow.appendChild(style);
                        if (this.paintCount === 0) {
                            // listen to click events
                            this.shadow.addEventListener('click', (event) => {
                              const clickedElement = event.target;
                              const actionTarget = clickedElement.closest('[on\\:click]');
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
                            let matches = this.shadow.querySelectorAll("input[on\\:change]")
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
                                            this.rubyComp["${'$'}"+trimmedActionVal](event, primValue);
                                          } else {
                                            this.rubyComp["${'$'}"+trimmedActionVal](event, value);
                                          }


                                       this.syncAttributes();
                                        this.render();
                                    });
                                }
                            }
                        }

                        $bindingCode
                        this.paintCount = this.paintCount + 1;
                    }
                }

                disconnectedCallback() {
                    this.rubyComp.${'$'}unmounted();
                }

                static get observedAttributes() {
                    return $reactables;
                }

                attributeChangedCallback(name, oldValue, newValue) {
                    console.log("Attribute " + name + " has changed from " + oldValue + " to " + newValue + "");
                    // TODO react to attributes changing
                    if (oldValue === newValue) {
                        return;
                    }
                    try {
                        let currentValue = this.rubyComp["${'$'}get_" + name]();
                        if (typeof currentValue === "number") {
                            // assign as number
                            this.rubyComp["${'$'}set_" + name](Number(newValue));
                        } else {
                            // assign as string
                            this.rubyComp["${'$'}set_" + name](newValue);
                        }
                        this.render();
                    } catch (e) {
                        console.error("Component render failed", e);
                    }
                }
            }
           customElements.define("$elName", $webCompName);
        """.trimIndent()
        return WebComp(webCompName, jsCode)
    }
}

data class WebComp(
    val name: String,
    val jsCode: String
)
