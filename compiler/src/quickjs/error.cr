module QuickJS
  class Error < Exception
    getter js_stack : String?

    def initialize(message : String, @js_stack : String? = nil)
      super(message)
    end
  end

  class EvalError < Error; end
  class TypeError < Error; end
  class ReferenceError < Error; end
  class SyntaxError < Error; end
  class RangeError < Error; end
  class InternalError < Error; end
end
