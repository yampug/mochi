require "spec"
require "../../src/js/runtime_kernel"
require "../../src/js/qjs_bindings"

describe JS::RuntimeKernel do
  it "executes signal and effect correctly via QuickJS" do
    runtime = LibQuickJS.js_newruntime
    ctx = LibQuickJS.js_newcontext(runtime)

    code = JS::RuntimeKernel.signals_code + <<-JS
      let [count, setCount] = createSignal(0);
      let [name, setName] = createSignal("Alice");
      let runs = 0;
      let lastCount = -1;
      let lastName = "";
      
      createEffect(() => {
        runs++;
        lastCount = count();
        lastName = name();
      });

      // Initial run
      if (runs !== 1) throw new Error("Expected initial run");
      if (lastCount !== 0) throw new Error("Expected initial count to be 0");
      if (lastName !== "Alice") throw new Error("Expected initial name to be Alice");

      // Update count
      setCount(1);
      if (runs !== 2) throw new Error("Expected run on count change");
      if (lastCount !== 1) throw new Error("Expected count 1");

      // Update name
      setName("Bob");
      if (runs !== 3) throw new Error("Expected run on name change");
      if (lastName !== "Bob") throw new Error("Expected name Bob");
      
      // Update with same value
      setCount(1);
      if (runs !== 3) throw new Error("Expected no run on same value");

      // Nested effect
      let nestedRuns = 0;
      let [outer, setOuter] = createSignal(10);
      let [inner, setInner] = createSignal(20);
      
      createEffect(() => {
        let o = outer();
        createEffect(() => {
          nestedRuns++;
          let i = inner();
        });
      });
      
      // Initial creation triggers both Outer -> Inner
      if (nestedRuns !== 1) throw new Error("Expected nested initial run");

      // changing inner triggers inner only
      setInner(21);
      if (nestedRuns !== 2) throw new Error("Nested effect didn't trigger");
    JS

    result = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "test.js".to_unsafe, 0)
    
    if QuickJS.is_exception?(result)
      exception = LibQuickJS.js_getexception(ctx)
      exc_str_val = LibQuickJS.js_tostring(ctx, exception)
      exc_str_ptr = LibQuickJS.js_tocstringlen2(ctx, nil, exc_str_val, false)
      exc_str = String.new(exc_str_ptr)
      LibQuickJS.js_freecstring(ctx, exc_str_ptr)
      LibQuickJS.js_freevalue(ctx, exc_str_val)
      LibQuickJS.js_freevalue(ctx, exception)
      fail(exc_str)
    end

    LibQuickJS.js_freevalue(ctx, result)
    LibQuickJS.js_freecontext(ctx)
    LibQuickJS.js_freeruntime(runtime)
  end
end
