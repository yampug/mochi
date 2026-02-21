module JS
  class RuntimeKernel
    def self.signals_code : String
      <<-JS
      let _mochi_ctx = [];
      function createSignal(v) {
        let subs = new Set();
        let get = () => {
          let c = _mochi_ctx[_mochi_ctx.length - 1];
          if (c) subs.add(c);
          return v;
        };
        let set = (nv) => {
          if (v !== nv) {
            v = nv;
            for (let s of [...subs]) s();
          }
        };
        return [get, set];
      }
      function createEffect(fn) {
        let ex = () => {
          _mochi_ctx.push(ex);
          try { fn(); } finally { _mochi_ctx.pop(); }
        };
        ex();
      }
      JS
    end
  end
end
