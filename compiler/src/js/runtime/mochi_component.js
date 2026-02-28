window._mochi_templates = {};

// Mochi Inter-Component Event Bus
window.Mochi = window.Mochi || {};
window.Mochi._events = window.Mochi._events || {};

window.Mochi.on = function (eventName, callback) {
    if (!window.Mochi._events[eventName]) {
        window.Mochi._events[eventName] = [];
    }
    window.Mochi._events[eventName].push(callback);
};

window.Mochi.off = function (eventName, callback) {
    if (!window.Mochi._events[eventName]) return;
    window.Mochi._events[eventName] = window.Mochi._events[eventName].filter(cb => cb !== callback);
};

window.Mochi.emit = function (eventName, payload) {
    if (!window.Mochi._events[eventName]) return;
    window.Mochi._events[eventName].forEach(cb => {
        try {
            cb(payload);
        } catch (e) {
            console.error(`Error in Mochi event handler for ${eventName}:`, e);
        }
    });
};

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

    disconnectedCallback() {
        if (this.rubyComp && typeof this.rubyComp.$_cleanup_mochi_subscriptions === 'function') {
            this.rubyComp.$_cleanup_mochi_subscriptions();
        }
        if (this.rubyComp && typeof this.rubyComp.$unmounted === 'function') {
            this.rubyComp.$unmounted();
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
        if (!this._eachItems) this._eachItems = {};
        const anchor = this.anchors[`each-anchor-${id}`];
        if (!anchor) return;

        const t = MochiComponent.getTemplate(templateId);
        const newItems = itemsFn() || [];
        const oldStates = this._eachItems[id] || [];

        // Build old key → state map
        const oldKeyMap = new Map();
        oldStates.forEach(s => oldKeyMap.set(s.key, s));

        const newStates = newItems.map((item, index) => ({
            key: keyFn ? keyFn(item, index) : index,
            item,
            index,
        }));
        const newKeySet = new Set(newStates.map(s => s.key));

        // Remove nodes for items no longer in the list
        oldKeyMap.forEach((old, key) => {
            if (!newKeySet.has(key)) {
                old.nodes.forEach(n => n.parentNode && n.parentNode.removeChild(n));
            }
        });

        // Insert/reorder items using the anchor as reference point
        let cursor = anchor;
        const nextStates = [];
        for (const { key, item, index } of newStates) {
            if (oldKeyMap.has(key)) {
                // Reuse existing nodes — patch text/attr bindings, preserve other state (e.g. CSS classes)
                const old = oldKeyMap.get(key);
                this._patchNodes(t, old.nodes, item, index);
                // Move nodes into position if not already there
                old.nodes.forEach(node => {
                    cursor.parentNode.insertBefore(node, cursor.nextSibling);
                    cursor = node;
                });
                nextStates.push({ key, nodes: old.nodes });
            } else {
                // New item — clone template
                const clone = t.content.cloneNode(true);
                this._substituteItemVars(clone, item, index);
                const nodes = Array.from(clone.childNodes);
                cursor.parentNode.insertBefore(clone, cursor.nextSibling);
                cursor = nodes[nodes.length - 1];
                nextStates.push({ key, nodes });
            }
        }

        this._eachItems[id] = nextStates;
    }

    // Patch live nodes against freshly-rendered template nodes.
    // Updates text content and bound attributes; preserves unbound attributes (e.g. user-added CSS classes).
    _patchNodes(template, oldNodes, item, index) {
        const frag = template.content.cloneNode(true);
        this._substituteItemVars(frag, item, index);
        const tmplNodes = Array.from(template.content.childNodes);
        const newNodes = Array.from(frag.childNodes);
        for (let i = 0; i < oldNodes.length && i < newNodes.length; i++) {
            this._patchNode(oldNodes[i], newNodes[i], tmplNodes[i]);
        }
    }

    _patchNode(old, nu, tmpl) {
        if (old.nodeType === 3) {
            // Text node: always sync content
            if (old.data !== nu.data) old.data = nu.data;
        } else if (old.nodeType === 1 && nu.nodeType === 1) {
            // Element: only update attributes that had a binding pattern in the template
            for (const attr of Array.from(nu.attributes)) {
                const tmplVal = tmpl && tmpl.getAttribute ? tmpl.getAttribute(attr.name) : null;
                const wasBound = tmplVal !== null && tmplVal.includes('{');
                if (wasBound && old.getAttribute(attr.name) !== attr.value) {
                    old.setAttribute(attr.name, attr.value);
                }
            }
            // Recurse into children
            const tmplChildren = tmpl ? Array.from(tmpl.childNodes) : [];
            const oldChildren = Array.from(old.childNodes);
            const nuChildren = Array.from(nu.childNodes);
            for (let i = 0; i < oldChildren.length && i < nuChildren.length; i++) {
                this._patchNode(oldChildren[i], nuChildren[i], tmplChildren[i] || null);
            }
        }
    }

    _substituteItemVars(root, item, index) {
        const sub = (v) => v
            .replace(/\{index\}/g, index)
            .replace(/\{item\.(\w+)\}/g, (_, p) => {
                try {
                    if (typeof item['$' + p] === 'function') return item['$' + p]();
                    if (item[p] !== undefined) return item[p];
                } catch (e) { }
                return '{item.' + p + '}';
            });
        const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT, null);
        let node;
        while ((node = walker.nextNode())) {
            if (node.nodeType === 3) {
                if (node.data.includes('{')) node.data = sub(node.data);
            } else {
                for (const attr of Array.from(node.attributes)) {
                    if (attr.value.includes('{')) node.setAttribute(attr.name, sub(attr.value));
                }
            }
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
