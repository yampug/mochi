require "./runtime"

module QuickJS
  class RuntimeBuilder
    @memory_limit : UInt64?
    @gc_threshold : UInt64?
    @modules : Array(String)

    def initialize
      @memory_limit = nil
      @gc_threshold = nil
      @modules = [] of String
    end

    def memory_limit(limit : Int32 | Int64)
      @memory_limit = limit.to_u64
      self
    end

    def gc_threshold(threshold : Int32 | Int64)
      @gc_threshold = threshold.to_u64
      self
    end

    def load_module(path : String)
      @modules << path
      self
    end

    def build : Runtime
      runtime = Runtime.new

      if limit = @memory_limit
        runtime.set_memory_limit(limit)
      end

      if threshold = @gc_threshold
        runtime.set_gc_threshold(threshold)
      end

      @modules.each do |mod|
        runtime.load_module(mod)
      end

      runtime
    end
  end

  def self.build(&block : RuntimeBuilder ->)
    builder = RuntimeBuilder.new
    yield builder
    builder.build
  end
end
