require "spec"
require "../../src/js/runtime_kernel"
require "../../src/js/qjs_bindings"

describe JS::RuntimeKernel do
  it "executes MochiComponent base class lifecycle correctly via QuickJS" do
    runtime = LibQuickJS.js_newruntime
    ctx = LibQuickJS.js_newcontext(runtime)

    code = JS::RuntimeKernel.component_code + <<-JS
      let mountFailed = false;
      let app = new MochiComponent();
      try {
        app.mount({});
      } catch(e) {
        mountFailed = true;
      }
      if (!mountFailed) throw new Error("Expected abstract mount to throw");

      let cleaned = 0;
      app.onCleanup(() => { cleaned++; });
      app.onCleanup(() => { cleaned += 2; });
      app.unmount();
      
      if (cleaned !== 3) throw new Error("Expected all cleanups to run, got " + cleaned);
      
      app.unmount();
      if (cleaned !== 3) throw new Error("Expected cleanups to strictly empty out after run");
      
      class CustomComponent extends MochiComponent {
        mount(target) {
          this.onCleanup(() => { target.run = true; });
        }
      }
      
      let cc = new CustomComponent();
      let parent = { run: false };
      cc.mount(parent);
      cc.unmount();
      if (!parent.run) throw new Error("Expected custom component cleanup");
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
