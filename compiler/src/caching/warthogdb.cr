require "./warthog_bindings"

class WarthogDB
  class Error < Exception; end

  class NotFoundError < Error; end

  class BufferTooSmallError < Error; end

  getter path : String

  @handle : LibWarthog::WarthogHandle
  @closed : Bool = false

  def initialize(
    @path : String,
    max_file_size : UInt32 = 1024_u32 * 1024_u32 * 10_u32,
    compaction_threshold : Float64 = 0.7,
    number_of_records : UInt32 = 10000_u32
  )
    @handle = LibWarthog.warthog_open(
      @path.to_unsafe,
      max_file_size,
      compaction_threshold,
      number_of_records
    )

    if @handle.null?
      raise Error.new("Failed to open WarthogDB at #{@path}")
    end
  end

  def self.open(
    path : String,
    max_file_size : UInt32 = 1024_u32 * 1024_u32 * 10_u32,
    compaction_threshold : Float64 = 0.7,
    number_of_records : UInt32 = 10000_u32
  )
    new(path, max_file_size, compaction_threshold, number_of_records)
  end

  def put(key : String, value : String) : Nil
    result = LibWarthog.warthog_put(
      @handle,
      key.to_unsafe,
      key.bytesize.to_u64,
      value.to_unsafe,
      value.bytesize.to_u64
    )

    if result != 0
      raise Error.new("Failed to put key: #{key}")
    end
  end

  def put(key : Bytes, value : Bytes) : Nil
    result = LibWarthog.warthog_put(
      @handle,
      key.to_unsafe,
      key.size.to_u64,
      value.to_unsafe,
      value.size.to_u64
    )

    if result != 0
      raise Error.new("Failed to put key")
    end
  end

  def get(key : String) : String?
    get_bytes(key.to_slice).try { |bytes| String.new(bytes) }
  end

  def get(key : Bytes) : Bytes?
    get_bytes(key)
  end

  def get_bytes(key : Bytes, initial_buffer_size : Int32 = 4096) : Bytes?
    buffer = Bytes.new(initial_buffer_size)
    out_len = 0_u64

    result = LibWarthog.warthog_get(
      @handle,
      key.to_unsafe,
      key.size.to_u64,
      buffer.to_unsafe,
      buffer.size.to_u64,
      pointerof(out_len)
    )

    case result
    when 0
      buffer[0, out_len]
    when 1
      nil
    when 2
      get_bytes(key, out_len.to_i * 2)
    else
      raise Error.new("Failed to get key")
    end
  end

  def []=(key : String, value : String)
    put(key, value)
  end

  def [](key : String) : String
    get(key) || raise NotFoundError.new("Key not found: #{key}")
  end

  def []?(key : String) : String?
    get(key)
  end

  def delete(key : String) : Nil
    result = LibWarthog.warthog_delete(
      @handle,
      key.to_unsafe,
      key.bytesize.to_u64
    )

    if result != 0
      raise Error.new("Failed to delete key: #{key}")
    end
  end

  def delete(key : Bytes) : Nil
    result = LibWarthog.warthog_delete(
      @handle,
      key.to_unsafe,
      key.size.to_u64
    )

    if result != 0
      raise Error.new("Failed to delete key")
    end
  end

  def snapshot : Snapshot
    Snapshot.new(self)
  end

  def each(&)
    iterator = Iterator.new(self)
    begin
      iterator.each do |key, value|
        yield key, value
      end
    ensure
      iterator.close
    end
  end

  def close : Nil
    return if @closed
    LibWarthog.warthog_close(@handle)
    @closed = true
  end

  def finalize
    close
  end

  class Snapshot
    @handle : LibWarthog::SnapshotHandle
    @db : WarthogDB
    @closed : Bool = false

    def initialize(@db : WarthogDB)
      @handle = LibWarthog.warthog_snapshot_open(@db.@handle)

      if @handle.null?
        raise Error.new("Failed to open snapshot")
      end
    end

    def get(key : String) : String?
      get_bytes(key.to_slice).try { |bytes| String.new(bytes) }
    end

    def get(key : Bytes) : Bytes?
      get_bytes(key)
    end

    def get_bytes(key : Bytes, initial_buffer_size : Int32 = 4096) : Bytes?
      buffer = Bytes.new(initial_buffer_size)
      out_len = 0_u64

      result = LibWarthog.warthog_snapshot_get(
        @db.@handle,
        @handle,
        key.to_unsafe,
        key.size.to_u64,
        buffer.to_unsafe,
        buffer.size.to_u64,
        pointerof(out_len)
      )

      case result
      when 0
        buffer[0, out_len]
      when 1
        nil
      when 2
        get_bytes(key, out_len.to_i * 2)
      else
        raise Error.new("Failed to get key from snapshot")
      end
    end

    def []?(key : String) : String?
      get(key)
    end

    def [](key : String) : String
      get(key) || raise NotFoundError.new("Key not found in snapshot: #{key}")
    end

    def each(&)
      iterator = Iterator.new(@db, self)
      begin
        iterator.each do |key, value|
          yield key, value
        end
      ensure
        iterator.close
      end
    end

    def close : Nil
      return if @closed
      LibWarthog.warthog_snapshot_close(@db.@handle, @handle)
      @closed = true
    end

    def finalize
      close
    end
  end

  class Iterator
    @handle : LibWarthog::IteratorHandle
    @db : WarthogDB
    @closed : Bool = false

    def initialize(@db : WarthogDB, snapshot : Snapshot? = nil)
      @handle = if snapshot
                  LibWarthog.warthog_snapshot_iter_open(@db.@handle, snapshot.@handle)
                else
                  LibWarthog.warthog_iter_open(@db.@handle)
                end

      if @handle.null?
        raise Error.new("Failed to open iterator")
      end
    end

    def each(&)
      key_buffer = Bytes.new(4096)
      val_buffer = Bytes.new(4096)
      key_len = 0_u64
      val_len = 0_u64

      loop do
        result = LibWarthog.warthog_iter_next(
          @handle,
          key_buffer.to_unsafe,
          key_buffer.size.to_u64,
          pointerof(key_len),
          val_buffer.to_unsafe,
          val_buffer.size.to_u64,
          pointerof(val_len)
        )

        case result
        when 1
          break
        when 0
          key = String.new(key_buffer[0, key_len])
          value = String.new(val_buffer[0, val_len])
          yield key, value
        when 2
          new_key_size = key_len > key_buffer.size ? key_len.to_i : key_buffer.size * 2
          new_val_size = val_len > val_buffer.size ? val_len.to_i : val_buffer.size * 2
          key_buffer = Bytes.new(new_key_size)
          val_buffer = Bytes.new(new_val_size)
          next
        else
          raise Error.new("Iterator error")
        end
      end
    end

    def close : Nil
      return if @closed
      LibWarthog.warthog_iter_close(@handle)
      @closed = true
    end

    def finalize
      close
    end
  end
end
