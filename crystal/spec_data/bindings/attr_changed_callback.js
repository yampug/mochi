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
