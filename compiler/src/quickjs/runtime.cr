require "../js/qjs_bindings"
require "./value"
require "./error"

module QuickJS
  class Runtime
    getter handle : LibQuickJS::JSRuntime
    getter context : LibQuickJS::JSContext

    def initialize
      @handle = LibQuickJS.js_newruntime
      @context = LibQuickJS.js_newcontext(@handle)
      @values = Set(Value).new
      @released = false
    end

    def finalize
      return if @released
      @released = true

      @values.each(&.finalize_internal)
      @values.clear

      LibQuickJS.js_freecontext(@context)
      LibQuickJS.js_freeruntime(@handle)
    end

    protected def track_value(value : Value)
      @values << value
    end

    protected def untrack_value(value : Value)
      @values.delete(value)
    end

    def eval(code : String, filename : String = "eval.js") : Value
      input = code.to_s
      fname = filename.to_s
      
      js_val = LibQuickJS.js_eval(
        @context,
        input.to_unsafe,
        input.bytesize,
        fname.to_unsafe,
        LibQuickJS::JS_EVAL_TYPE_GLOBAL
      )

      if QuickJS.is_exception?(js_val)
        check_exception!
        raise Error.new("Unknown error during evaluation") 
      end

      val = Value.new(self, js_val)
      LibQuickJS.js_freevalue(@context, js_val)
      val
    end

    def eval_file(path : String) : Value
      code = File.read(path)
      eval(code, path)
    end

    def [](key : String) : Value
      global = LibQuickJS.js_getglobalobject(@context)
      prop = LibQuickJS.js_getpropertystr(@context, global, key)
      LibQuickJS.js_freevalue(@context, global)
      
      val = Value.new(self, prop)
      LibQuickJS.js_freevalue(@context, prop)
      val
    end

    def []=(key : String, value)
      global = LibQuickJS.js_getglobalobject(@context)
      js_val = to_js_value(value)
      
      LibQuickJS.js_setpropertystr(@context, global, key, js_val)
      LibQuickJS.js_freevalue(@context, global)
    end

    def call(function_name : String, *args) : Value
      global = LibQuickJS.js_getglobalobject(@context)
      func_obj = LibQuickJS.js_getpropertystr(@context, global, function_name)
      LibQuickJS.js_freevalue(@context, global)

      if LibQuickJS.js_isfunction(@context, func_obj) == 0
        LibQuickJS.js_freevalue(@context, func_obj)
        raise TypeError.new("'#{function_name}' is not a function")
      end
      
      js_args = args.map { |arg| to_js_value(arg) }.to_a
      
      result = LibQuickJS.js_call(@context, func_obj, QuickJS::UNDEFINED, js_args.size, js_args.to_unsafe)
      LibQuickJS.js_freevalue(@context, func_obj)
      
      if QuickJS.is_exception?(result)
        check_exception!
        raise Error.new("Error calling function '#{function_name}'")
      end

      val = Value.new(self, result)
      LibQuickJS.js_freevalue(@context, result)
      val
    end

    def to_js_value(value : Int32) : LibQuickJS::JSValue
      QuickJS.mkval(LibQuickJS::JS_TAG_INT, value)
    end

    def to_js_value(value : Int64) : LibQuickJS::JSValue
       LibQuickJS.js_newbigint64(@context, value)
    end

    def to_js_value(value : Float64) : LibQuickJS::JSValue
      LibQuickJS.js_newnumber(@context, value)
    end

    def to_js_value(value : String) : LibQuickJS::JSValue
      LibQuickJS.js_newstringlen(@context, value.to_unsafe, value.bytesize)
    end

    def to_js_value(value : Bool) : LibQuickJS::JSValue
      value ? QuickJS::TRUE : QuickJS::FALSE
    end

    def to_js_value(value : Nil) : LibQuickJS::JSValue
      QuickJS::NULL
    end

    def to_js_value(value : Value) : LibQuickJS::JSValue
      LibQuickJS.js_dupvalue(@context, value.handle)
    end

    def to_js_value(value : Array) : LibQuickJS::JSValue
      arr = LibQuickJS.js_newarray(@context)
      value.each_with_index do |v, i|
        js_v = to_js_value(v)
        LibQuickJS.js_setpropertyuint32(@context, arr, i, js_v)
      end
      arr
    end
    
    def to_js_value(value : Hash) : LibQuickJS::JSValue
      obj = LibQuickJS.js_newobject(@context)
      value.each do |k, v|
        js_v = to_js_value(v)
        LibQuickJS.js_setpropertystr(@context, obj, k.to_s, js_v)
      end
      obj
    end

    def gc
      LibQuickJS.js_rungc(@handle)
    end

    def set_memory_limit(limit : UInt64)
      LibQuickJS.js_setmemorylimit(@handle, limit)
    end

    def set_gc_threshold(threshold : UInt64)
      LibQuickJS.js_setgcthreshold(@handle, threshold)
    end

    # Callbacks
    def register_function(name : String, &block : Array(Value) -> Value)
      raise Error.new("Registering functions with closures not fully implemented yet without C shim extensions")
    end 
    
    def run_jobs
      pctx = Pointer(Void).null.as(LibQuickJS::JSContext)
      loop do
        ret = LibQuickJS.js_executependingjob(@handle, pointerof(pctx))
        break if ret == 0
        if ret < 0
             break
        end
      end
    end

    def eval_async(code : String) : Value
      val = eval(code)
      run_jobs if val.promise?
      val
    end

    # Modules
    def load_module(path : String) : Value
      code = File.read(path)
      
      js_val = LibQuickJS.js_eval(
        @context,
        code.to_unsafe,
        code.bytesize,
        path.to_unsafe,
        LibQuickJS::JS_EVAL_TYPE_MODULE
      )

      if QuickJS.is_exception?(js_val)
        check_exception!
        raise Error.new("Failed to compile module")
      end
      
      val = Value.new(self, js_val)
      LibQuickJS.js_freevalue(@context, js_val)
      val
    end

    protected def check_exception!
       exception_val = LibQuickJS.js_getexception(@context)
       
       str_val = LibQuickJS.js_tostring(@context, exception_val)
       str_ptr = LibQuickJS.js_tocstringlen2(@context, nil, str_val, false)
       message = String.new(str_ptr)
       
       LibQuickJS.js_freecstring(@context, str_ptr)
       LibQuickJS.js_freevalue(@context, str_val)
       
       LibQuickJS.js_freevalue(@context, exception_val)

       case message
       when /^SyntaxError:/
         raise SyntaxError.new(message)
       when /^ReferenceError:/
         raise ReferenceError.new(message)
       when /^TypeError:/
         raise TypeError.new(message)
       when /^RangeError:/
         raise RangeError.new(message)
       when /^InternalError:/
         raise InternalError.new(message)
       when /^EvalError:/
         raise EvalError.new(message) 
       else
         raise Error.new(message)
       end
    end
  end
end
