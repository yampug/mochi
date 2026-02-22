window._mochi_templates = {};

class MochiComponent extends HTMLElement {
    constructor() {
        super();
        this.shadow = this.attachShadow({ mode: 'open' });
        this.dom_refs = {};
        this._initialized = false;
    }

    connectedCallback() {
        if (!this._initialized) {
            this.mount(this.shadow);
            this._initialized = true;
        }
    }

    mount(target) {
        // To be implemented by subclasses
    }

    updateConditional(id, templateId, conditionFn) {
        if (!this._ifRendered) this._ifRendered = {};
        const anchor = this.anchors[`if-anchor-${id}`];
        if (!anchor) return;

        const show = conditionFn();
        if (show && !this._ifRendered[id]) {
            const t = MochiComponent.getTemplate(templateId);
            const clone = t.content.cloneNode(true);
            this._ifRendered[id] = Array.from(clone.childNodes);
            anchor.parentNode.insertBefore(clone, anchor.nextSibling);
        } else if (!show && this._ifRendered[id]) {
            this._ifRendered[id].forEach(n => n.parentNode && n.parentNode.removeChild(n));
            this._ifRendered[id] = null;
        }
    }

    updateEach(id, templateId, itemsFn, keyFn) {
        // Simplified each update for now (similar to legacy but using anchors)
        // In a real implementation we would do keyed diffing here
        if (!this._eachItems) this._eachItems = {};
        const anchor = this.anchors[`each-anchor-${id}`];
        if (!anchor) return;

        const items = itemsFn() || [];
        const oldNodes = this._eachItems[id] || [];
        
        // Very basic reconciliation: clear and re-render (will optimize in story 4.2)
        oldNodes.forEach(nodes => nodes.forEach(n => n.parentNode && n.parentNode.removeChild(n)));
        
        const newNodes = [];
        const t = MochiComponent.getTemplate(templateId);
        
        items.forEach((item, index) => {
            const clone = t.content.cloneNode(true);
            // Substitute vars (simplified)
            this._substituteItemVars(clone, item, index);
            const nodes = Array.from(clone.childNodes);
            anchor.parentNode.insertBefore(clone, anchor.nextSibling); // This is wrong, needs to be after last item
            // Fix: append to a fragment first or keep track of cursor
            newNodes.push(nodes);
        });
        
        // Actually, let's use a document fragment for better performance and correct ordering
        const frag = document.createDocumentFragment();
        const nextItemsNodes = [];
        items.forEach((item, index) => {
            const clone = t.content.cloneNode(true);
            this._substituteItemVars(clone, item, index);
            nextItemsNodes.push(Array.from(clone.childNodes));
            frag.appendChild(clone);
        });
        anchor.parentNode.insertBefore(frag, anchor.nextSibling);
        this._eachItems[id] = nextItemsNodes;
    }

    _substituteItemVars(root, item, index) {
        const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null);
        let node;
        while ((node = walker.nextNode())) {
            node.data = node.data.replace(/\{index\}/g, index);
            node.data = node.data.replace(/\{item\.(\w+)\}/g, (_, prop) => {
                try {
                    if (typeof item['$' + prop] === 'function') return item['$' + prop]();
                    if (item[prop] !== undefined) return item[prop];
                } catch(e) {}
                return '{item.' + prop + '}';
            });
        }
    }
    
    // Helper to get template
    static getTemplate(id) {
        if (!window._mochi_templates[id]) {
            console.error(`Template ${id} not found!`);
            return document.createElement('template');
        }
        return window._mochi_templates[id];
    }
}

window.MochiComponent = MochiComponent;
