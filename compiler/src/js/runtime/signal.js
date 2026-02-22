
class Signal {
    constructor(val) {
        this._val = val;
        this._subs = new Set();
    }
    
    get() {
        if (Signal.context) {
            this._subs.add(Signal.context);
            if (!Signal.context.deps) Signal.context.deps = new Set();
            Signal.context.deps.add(this);
        }
        return this._val;
    }
    
    set(newVal) {
        if (this._val === newVal) return;
        this._val = newVal;
        for (let sub of this._subs) {
            sub.run();
        }
    }
}

Signal.context = null;

function createSignal(val) {
    const s = new Signal(val);
    return [() => s.get(), (v) => s.set(v)];
}

function createEffect(fn) {
    const effect = {
        run() {
            // cleanup old dependencies
            if (this.deps) {
                for(let dep of this.deps) {
                    dep._subs.delete(this);
                }
                this.deps.clear();
            }
            
            const prev = Signal.context;
            Signal.context = this;
            try {
                fn();
            } finally {
                Signal.context = prev;
            }
        }
    };
    effect.run();
    return effect;
}

window.createSignal = createSignal;
window.createEffect = createEffect;
