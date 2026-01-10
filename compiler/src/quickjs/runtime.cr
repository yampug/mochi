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

    def gc
      LibQuickJS.js_rungc(@handle)
    end

    private def check_exception!
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
