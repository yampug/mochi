require "../js/qjs_bindings"
require "./error"

module QuickJS
  class Value
    getter handle : LibQuickJS::JSValue
    getter runtime : Runtime

    def initialize(@runtime : Runtime, @handle : LibQuickJS::JSValue)
      @handle = LibQuickJS.js_dupvalue(@runtime.context, @handle)
      @runtime.track_value(self)
      @freed = false
    end

    def finalize
      finalize_internal
      @runtime.untrack_value(self)
    end

    protected def finalize_internal
      return if @freed
      @freed = true
      LibQuickJS.js_freevalue(@runtime.context, @handle)
    end

    def undefined? : Bool
      QuickJS.is_undefined?(@handle)
    end

    def null? : Bool
      QuickJS.is_null?(@handle)
    end

    def boolean? : Bool
      QuickJS.is_bool?(@handle)
    end

    def number? : Bool
      QuickJS.is_number?(@handle)
    end

    def string? : Bool
      QuickJS.is_string?(@handle)
    end

    def object? : Bool
      QuickJS.is_object?(@handle)
    end

    def array? : Bool
      LibQuickJS.js_isarray(@handle)
    end

    def function? : Bool
      LibQuickJS.js_isfunction(@runtime.context, @handle)
    end

    def exception? : Bool
      QuickJS.is_exception?(@handle)
    end

    def to_i : Int32
      raise TypeError.new("Value is not a number") unless number?

      result = 0
      ret = LibQuickJS.js_toint32(@runtime.context, pointerof(result), @handle)
      raise Error.new("Conversion to Int32 failed") if ret != 0
      result
    end

    def to_i64 : Int64
      raise TypeError.new("Value is not a number") unless number?

      result = 0_i64
      ret = LibQuickJS.js_toint64(@runtime.context, pointerof(result), @handle)
      raise Error.new("Conversion to Int64 failed") if ret != 0
      result
    end

    def to_f : Float64
      raise TypeError.new("Value is not a number") unless number?

      result = 0.0
      ret = LibQuickJS.js_tofloat64(@runtime.context, pointerof(result), @handle)
      raise Error.new("Conversion to Float64 failed") if ret != 0
      result
    end

    def to_s : String
      str_val = LibQuickJS.js_tostring(@runtime.context, @handle)
      
      if QuickJS.is_exception?(str_val)
         LibQuickJS.js_freevalue(@runtime.context, str_val)
         raise Error.new("Could not convert value to string")
      end

      plen = 0_u64
      str_ptr = LibQuickJS.js_tocstringlen2(@runtime.context, pointerof(plen), str_val, false)
      
      if str_ptr.null?
         LibQuickJS.js_freevalue(@runtime.context, str_val)
         raise Error.new("Could not get C string from value")
      end

      result = String.new(str_ptr, plen)
      
      LibQuickJS.js_freecstring(@runtime.context, str_ptr)
      LibQuickJS.js_freevalue(@runtime.context, str_val)
      
      result
    end

    def to_bool : Bool
      res = LibQuickJS.js_tobool(@runtime.context, @handle)
      if res == -1
        raise Error.new("Could not convert value to boolean")
      end
      res != 0
    end

    def to_a : Array(Value)
      raise TypeError.new("Value is not an array") unless array?
      
      result = [] of Value
      each do |val|
        result << val
      end
      result
    end

    def to_h : Hash(String, Value)
      raise TypeError.new("Value is not an object") unless object?
      
      result = {} of String => Value
      keys.each do |key|
        result[key] = self[key]
      end
      result
    end

    def [](key : String) : Value
      prop = LibQuickJS.js_getpropertystr(@runtime.context, @handle, key)
      Value.new(@runtime, prop)
    end

    def [](index : Int32) : Value
      prop = LibQuickJS.js_getpropertyuint32(@runtime.context, @handle, index.to_u32)
      Value.new(@runtime, prop)
    end

    def []=(key : String, value)
      js_val = @runtime.to_js_value(value)
      LibQuickJS.js_setpropertystr(@runtime.context, @handle, key, js_val)
    end

    def []=(index : Int32, value)
      js_val = @runtime.to_js_value(value)
      LibQuickJS.js_setpropertyuint32(@runtime.context, @handle, index.to_u32, js_val)
    end
    
    def has_key?(key : String) : Bool
       atom = LibQuickJS.js_newatom(@runtime.context, key)
       ret = LibQuickJS.js_hasproperty(@runtime.context, @handle, atom)
       LibQuickJS.js_freeatom(@runtime.context, atom)
       ret != 0
    end

    def keys : Array(String)
      global = LibQuickJS.js_getglobalobject(@runtime.context)
      object_cls = LibQuickJS.js_getpropertystr(@runtime.context, global, "Object")
      keys_func = LibQuickJS.js_getpropertystr(@runtime.context, object_cls, "keys")
      
      args = [@handle]
      result = LibQuickJS.js_call(@runtime.context, keys_func, QuickJS::UNDEFINED, 1, pointerof(@handle))
      
      LibQuickJS.js_freevalue(@runtime.context, keys_func)
      LibQuickJS.js_freevalue(@runtime.context, object_cls)
      LibQuickJS.js_freevalue(@runtime.context, global)
      
      if QuickJS.is_exception?(result)
         LibQuickJS.js_freevalue(@runtime.context, result)
         raise Error.new("Failed to get keys")
      end

      # result is an array of strings
      # Convert to Crystal Array(String)
      keys_val = Value.new(@runtime, result)
      arr = [] of String
      keys_val.each do |k|
        arr << k.to_s
      end
      
      keys_val.each do |k|
        arr << k.to_s
      end
      
      arr
    end

    def call(*args) : Value
      call(nil, *args)
    end

    def call(this_obj : Value?, *args) : Value
      raise TypeError.new("Value is not a function") unless function?
      
      js_this = this_obj ? this_obj.handle : QuickJS::UNDEFINED
      
      js_args = args.map { |arg| @runtime.to_js_value(arg) }.to_a
      
      result = LibQuickJS.js_call(@runtime.context, @handle, js_this, js_args.size, js_args.to_unsafe)
      
      if QuickJS.is_exception?(result)
        @runtime.check_exception!
        raise Error.new("Function call failed") # Fallback
      end

      Value.new(@runtime, result)
    end


    def size : Int32
      len_val = LibQuickJS.js_getpropertystr(@runtime.context, @handle, "length")
      val = Value.new(@runtime, len_val)
      val.to_i 
    end

    def each(&block : Value ->)
      sz = size
      sz.times do |i|
        yield self[i]
      end
    end

    def map(&block : Value -> T) : Array(T) forall T
      result = [] of T
      each do |val|
        result << yield val
      end
      result
    end
    def as_i(default = 0) : Int32
      to_i
    rescue
      default
    end

    def as_f(default = 0.0) : Float64
      to_f
    rescue
      default
    end

    def as_s(default = "") : String
      to_s
    rescue
      default
    end

    def as_bool(default = false) : Bool
      to_bool
    rescue
      default
    end
  end
end
