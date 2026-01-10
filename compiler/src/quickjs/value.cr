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
