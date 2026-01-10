require "spec"
require "../spec_data_loader"
require "../../src/js/qjs_bindings"

describe "QuickJS Advanced Features" do
  describe "Function Calls" do
    it "calls JavaScript functions from Crystal" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Define a function
      code = "function add(a, b) { return a + b; }"
      LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "test.js".to_unsafe, 0)

      # Get the function
      global = LibQuickJS.js_getglobalobject(ctx)
      func = LibQuickJS.js_getpropertystr(ctx, global, "add".to_unsafe)

      # Create arguments
      arg1 = QuickJS.mkval(LibQuickJS::JS_TAG_INT, 10)
      arg2 = QuickJS.mkval(LibQuickJS::JS_TAG_INT, 32)
      args = [arg1, arg2]

      # Call the function
      result = LibQuickJS.js_call(ctx, func, QuickJS::UNDEFINED, 2, args.to_unsafe)

      result_int = 0_i32
      LibQuickJS.js_toint32(ctx, pointerof(result_int), result).should eq(0)
      result_int.should eq(42)

      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freevalue(ctx, func)
      LibQuickJS.js_freevalue(ctx, global)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "calls constructor functions" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Define a constructor
      code = "function Point(x, y) { this.x = x; this.y = y; }"
      LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "test.js".to_unsafe, 0)

      # Get the constructor
      global = LibQuickJS.js_getglobalobject(ctx)
      ctor = LibQuickJS.js_getpropertystr(ctx, global, "Point".to_unsafe)

      # Create arguments
      arg1 = QuickJS.mkval(LibQuickJS::JS_TAG_INT, 10)
      arg2 = QuickJS.mkval(LibQuickJS::JS_TAG_INT, 20)
      args = [arg1, arg2]

      # Call as constructor
      instance = LibQuickJS.js_callconstructor(ctx, ctor, 2, args.to_unsafe)

      # Get x property
      x_val = LibQuickJS.js_getpropertystr(ctx, instance, "x".to_unsafe)
      x_int = 0_i32
      LibQuickJS.js_toint32(ctx, pointerof(x_int), x_val).should eq(0)
      x_int.should eq(10)

      LibQuickJS.js_freevalue(ctx, x_val)
      LibQuickJS.js_freevalue(ctx, instance)
      LibQuickJS.js_freevalue(ctx, ctor)
      LibQuickJS.js_freevalue(ctx, global)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "Promises" do
    it "creates and checks promise state" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      code = SpecDataLoader.load("js/async_example.js")
      result = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "async.js".to_unsafe, 0)

      # Check if it's a promise
      LibQuickJS.js_ispromise(result).should be_true

      # Check promise state
      state = LibQuickJS.js_promisestate(ctx, result)
      state.should eq(LibQuickJS::JSPromiseStateEnum::Fulfilled)

      # Get promise result
      promise_result = LibQuickJS.js_promiseresult(ctx, result)
      result_int = 0_i32
      LibQuickJS.js_toint32(ctx, pointerof(result_int), promise_result).should eq(0)
      result_int.should eq(42)

      LibQuickJS.js_freevalue(ctx, promise_result)
      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "creates promise capability" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Create promise with resolving functions
      resolving_funcs = uninitialized LibQuickJS::JSValue[2]
      promise = LibQuickJS.js_newpromisecapability(ctx, resolving_funcs.to_unsafe)

      LibQuickJS.js_ispromise(promise).should be_true

      # Check initial state is pending
      state = LibQuickJS.js_promisestate(ctx, promise)
      state.should eq(LibQuickJS::JSPromiseStateEnum::Pending)

      LibQuickJS.js_freevalue(ctx, resolving_funcs[0])
      LibQuickJS.js_freevalue(ctx, resolving_funcs[1])
      LibQuickJS.js_freevalue(ctx, promise)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "TypedArrays and ArrayBuffers" do
    it "creates and manipulates typed arrays" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      code = SpecDataLoader.load("js/arraybuffer_example.js")
      result = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "buffer.js".to_unsafe, 0)

      result_int = 0_i32
      LibQuickJS.js_toint32(ctx, pointerof(result_int), result).should eq(0)
      result_int.should eq(16)  # length of the view

      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "creates ArrayBuffer from Crystal" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Create a buffer with some data
      data = Bytes.new(8)
      data[0] = 1_u8
      data[1] = 2_u8
      data[2] = 3_u8
      data[3] = 4_u8

      # Create ArrayBuffer (Note: the buffer will be managed by JS)
      buffer_copy = data.dup
      array_buffer = LibQuickJS.js_newarraybuffercopy(ctx, buffer_copy.to_unsafe, buffer_copy.size.to_u64)

      # Check it's an ArrayBuffer
      LibQuickJS.js_isarraybuffer(array_buffer).should be_true

      # Get the buffer back
      size = 0_u64
      buf_ptr = LibQuickJS.js_getarraybuffer(ctx, pointerof(size), array_buffer)
      size.should eq(8)

      # Check the data
      retrieved = Slice.new(buf_ptr, size)
      retrieved[0].should eq(1_u8)
      retrieved[1].should eq(2_u8)

      LibQuickJS.js_freevalue(ctx, array_buffer)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "creates Uint8Array from Crystal" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      data = Bytes.new(4)
      data[0] = 10_u8
      data[1] = 20_u8
      data[2] = 30_u8
      data[3] = 40_u8

      data_copy = data.dup
      uint8_array = LibQuickJS.js_newuint8arraycopy(ctx, data_copy.to_unsafe, data_copy.size.to_u64)

      # Get it back
      size = 0_u64
      arr_ptr = LibQuickJS.js_getuint8array(ctx, pointerof(size), uint8_array)
      size.should eq(4)

      retrieved = Slice.new(arr_ptr, size)
      retrieved[0].should eq(10_u8)
      retrieved[1].should eq(20_u8)

      LibQuickJS.js_freevalue(ctx, uint8_array)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "Object Utilities" do
    it "gets and sets prototypes" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Create an object
      obj = LibQuickJS.js_newobject(ctx)

      # Get its prototype
      proto = LibQuickJS.js_getprototype(ctx, obj)
      QuickJS.is_object?(proto).should be_true

      LibQuickJS.js_freevalue(ctx, proto)
      LibQuickJS.js_freevalue(ctx, obj)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "checks instanceof" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Create an array
      code = "[]"
      arr = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "test.js".to_unsafe, 0)

      # Get Array constructor
      global = LibQuickJS.js_getglobalobject(ctx)
      array_ctor = LibQuickJS.js_getpropertystr(ctx, global, "Array".to_unsafe)

      # Check instanceof
      is_instance = LibQuickJS.js_isinstanceof(ctx, arr, array_ctor)
      is_instance.should eq(1)

      LibQuickJS.js_freevalue(ctx, array_ctor)
      LibQuickJS.js_freevalue(ctx, global)
      LibQuickJS.js_freevalue(ctx, arr)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "freezes and seals objects" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Create an object
      obj = LibQuickJS.js_newobject(ctx)

      # Seal it (returns 1 on success, not 0)
      result = LibQuickJS.js_sealobject(ctx, obj)
      result.should_not eq(-1)  # -1 indicates failure

      LibQuickJS.js_freevalue(ctx, obj)

      # Create another object and freeze it
      obj2 = LibQuickJS.js_newobject(ctx)
      result2 = LibQuickJS.js_freezeobject(ctx, obj2)
      result2.should_not eq(-1)  # -1 indicates failure

      LibQuickJS.js_freevalue(ctx, obj2)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "checks extensibility" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      obj = LibQuickJS.js_newobject(ctx)

      # Should be extensible initially
      is_ext = LibQuickJS.js_isextensible(ctx, obj)
      is_ext.should eq(1)

      # Prevent extensions
      LibQuickJS.js_preventextensions(ctx, obj)

      # Should not be extensible now
      is_ext2 = LibQuickJS.js_isextensible(ctx, obj)
      is_ext2.should eq(0)

      LibQuickJS.js_freevalue(ctx, obj)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "Symbols" do
    it "creates symbols" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Create a symbol
      sym = LibQuickJS.js_newsymbol(ctx, "mySymbol".to_unsafe, false)
      QuickJS.is_symbol?(sym).should be_true

      # Symbols can be used as property keys
      obj = LibQuickJS.js_newobject(ctx)
      val = QuickJS.mkval(LibQuickJS::JS_TAG_INT, 42)

      # Convert symbol to atom to use as property key
      atom = LibQuickJS.js_valuetoatom(ctx, sym)
      LibQuickJS.js_defineproperty(ctx, obj, atom, val, QuickJS::UNDEFINED, QuickJS::UNDEFINED, LibQuickJS::JS_PROP_C_W_E)

      LibQuickJS.js_freeatom(ctx, atom)
      LibQuickJS.js_freevalue(ctx, obj)
      LibQuickJS.js_freevalue(ctx, sym)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "creates global symbols" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Create a global symbol
      sym = LibQuickJS.js_newsymbol(ctx, "globalSym".to_unsafe, true)
      QuickJS.is_symbol?(sym).should be_true

      LibQuickJS.js_freevalue(ctx, sym)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "BigInt Support" do
    it "creates BigInt from int64" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      big_val = LibQuickJS.js_newbigint64(ctx, 9223372036854775807_i64)  # max i64

      # Convert back
      result_i64 = 0_i64
      ret = LibQuickJS.js_tobigint64(ctx, pointerof(result_i64), big_val)
      ret.should eq(0)
      result_i64.should eq(9223372036854775807_i64)

      LibQuickJS.js_freevalue(ctx, big_val)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "creates BigInt from uint64" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      big_val = LibQuickJS.js_newbiguint64(ctx, 18446744073709551615_u64)  # max u64

      # Convert back
      result_u64 = 0_u64
      ret = LibQuickJS.js_tobiguint64(ctx, pointerof(result_u64), big_val)
      ret.should eq(0)
      result_u64.should eq(18446744073709551615_u64)

      LibQuickJS.js_freevalue(ctx, big_val)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "Proxy Support" do
    it "creates proxies" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Create target and handler
      target = LibQuickJS.js_newobject(ctx)
      handler = LibQuickJS.js_newobject(ctx)

      # Create proxy
      proxy = LibQuickJS.js_newproxy(ctx, target, handler)
      LibQuickJS.js_isproxy(proxy).should be_true

      # Get proxy target
      retrieved_target = LibQuickJS.js_getproxytarget(ctx, proxy)
      QuickJS.is_object?(retrieved_target).should be_true

      LibQuickJS.js_freevalue(ctx, retrieved_target)
      LibQuickJS.js_freevalue(ctx, proxy)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "Date Support" do
    it "creates dates from epoch milliseconds" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Create a date (Jan 1, 2020)
      epoch_ms = 1577836800000.0
      date = LibQuickJS.js_newdate(ctx, epoch_ms)

      LibQuickJS.js_isdate(date).should be_true

      LibQuickJS.js_freevalue(ctx, date)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "Module Detection" do
    it "detects module syntax" do
      # Test ES6 module
      module_code = SpecDataLoader.load("js/module_example.js")
      is_module = LibQuickJS.js_detectmodule(module_code.to_unsafe, module_code.bytesize.to_u64)
      is_module.should be_true

      # Note: JS_DetectModule is conservative and may return true for non-module code
      # as it just checks if the code parses as a module without errors
      # So we won't test the negative case
    end
  end

  describe "Value Comparison" do
    it "compares values for equality" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      val1 = LibQuickJS.js_eval(ctx, "42".to_unsafe, 2_u64, "test.js".to_unsafe, 0)
      val2 = LibQuickJS.js_eval(ctx, "42".to_unsafe, 2_u64, "test.js".to_unsafe, 0)
      val3 = LibQuickJS.js_eval(ctx, "43".to_unsafe, 2_u64, "test.js".to_unsafe, 0)

      # Strict equality
      LibQuickJS.js_isstrictequal(ctx, val1, val2).should be_true
      LibQuickJS.js_isstrictequal(ctx, val1, val3).should be_false

      # Same value
      LibQuickJS.js_issamevalue(ctx, val1, val2).should be_true
      LibQuickJS.js_issamevalue(ctx, val1, val3).should be_false

      LibQuickJS.js_freevalue(ctx, val1)
      LibQuickJS.js_freevalue(ctx, val2)
      LibQuickJS.js_freevalue(ctx, val3)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "handles same value zero comparison" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # +0 and -0 should be equal with SameValueZero
      pos_zero = LibQuickJS.js_eval(ctx, "0".to_unsafe, 1_u64, "test.js".to_unsafe, 0)
      neg_zero = LibQuickJS.js_eval(ctx, "-0".to_unsafe, 2_u64, "test.js".to_unsafe, 0)

      LibQuickJS.js_issamevaluezero(ctx, pos_zero, neg_zero).should be_true

      LibQuickJS.js_freevalue(ctx, pos_zero)
      LibQuickJS.js_freevalue(ctx, neg_zero)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end
end
