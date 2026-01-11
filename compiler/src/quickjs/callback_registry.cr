module QuickJS
  class CallbackRegistry
    @@callbacks = {} of UInt32 => Proc(Array(Value), Value)
    @@next_id = 1_u32

    def self.register(proc : Proc(Array(Value), Value)) : UInt32
      id = @@next_id
      @@callbacks[id] = proc
      @@next_id += 1
      id
    end

    def self.unregister(id : UInt32)
      @@callbacks.delete(id)
    end

    def self.call(id : UInt32, args : Array(Value)) : Value
      if callback = @@callbacks[id]?
        callback.call(args)
      else
        raise "Callback #{id} not found"
      end
    end
  end
end
