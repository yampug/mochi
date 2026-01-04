require "spec"
require "../src/caching/warthog_bindings"

describe "LibWarthog" do
  it "opens and closes database" do
    db_path = "/tmp/test_warthog_db_#{Time.utc.to_unix_ms}"
    handle = LibWarthog.warthog_open(
      db_path.to_unsafe,
      1024_u32 * 1024_u32 * 10_u32,
      0.7,
      10000_u32
    )
    handle.should_not be_nil
    LibWarthog.warthog_close(handle)
  end

  it "puts and gets a value" do
    db_path = "/tmp/test_warthog_db_#{Time.utc.to_unix_ms}"
    handle = LibWarthog.warthog_open(
      db_path.to_unsafe,
      1024_u32 * 1024_u32 * 10_u32,
      0.7,
      10000_u32
    )
    handle.should_not be_nil

    key = "test_key"
    value = "test_value"

    result = LibWarthog.warthog_put(
      handle,
      key.to_unsafe,
      key.bytesize.to_u64,
      value.to_unsafe,
      value.bytesize.to_u64
    )
    result.should eq(0)

    buffer = Bytes.new(1024)
    out_len = 0_u64

    get_result = LibWarthog.warthog_get(
      handle,
      key.to_unsafe,
      key.bytesize.to_u64,
      buffer.to_unsafe,
      buffer.size.to_u64,
      pointerof(out_len)
    )

    get_result.should eq(0)
    out_len.should eq(value.bytesize)
    String.new(buffer[0, out_len]).should eq(value)

    LibWarthog.warthog_close(handle)
  end

  it "returns not found for missing key" do
    db_path = "/tmp/test_warthog_db_#{Time.utc.to_unix_ms}"
    handle = LibWarthog.warthog_open(
      db_path.to_unsafe,
      1024_u32 * 1024_u32 * 10_u32,
      0.7,
      10000_u32
    )
    handle.should_not be_nil

    key = "missing_key"
    buffer = Bytes.new(1024)
    out_len = 0_u64

    get_result = LibWarthog.warthog_get(
      handle,
      key.to_unsafe,
      key.bytesize.to_u64,
      buffer.to_unsafe,
      buffer.size.to_u64,
      pointerof(out_len)
    )

    get_result.should eq(1)

    LibWarthog.warthog_close(handle)
  end

  it "deletes a value" do
    db_path = "/tmp/test_warthog_db_#{Time.utc.to_unix_ms}"
    handle = LibWarthog.warthog_open(
      db_path.to_unsafe,
      1024_u32 * 1024_u32 * 10_u32,
      0.7,
      10000_u32
    )
    handle.should_not be_nil

    key = "delete_test"
    value = "to_be_deleted"

    LibWarthog.warthog_put(
      handle,
      key.to_unsafe,
      key.bytesize.to_u64,
      value.to_unsafe,
      value.bytesize.to_u64
    )

    delete_result = LibWarthog.warthog_delete(
      handle,
      key.to_unsafe,
      key.bytesize.to_u64
    )
    delete_result.should eq(0)

    buffer = Bytes.new(1024)
    out_len = 0_u64

    get_result = LibWarthog.warthog_get(
      handle,
      key.to_unsafe,
      key.bytesize.to_u64,
      buffer.to_unsafe,
      buffer.size.to_u64,
      pointerof(out_len)
    )

    get_result.should eq(1)

    LibWarthog.warthog_close(handle)
  end

  it "opens and closes snapshots" do
    db_path = "/tmp/test_warthog_snapshot_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    handle = LibWarthog.warthog_open(
      db_path.to_unsafe,
      1024_u32 * 1024_u32,
      0.7,
      10000_u32
    )
    handle.should_not be_nil

    key = "test_key"
    value = "test_value"

    LibWarthog.warthog_put(
      handle,
      key.to_unsafe,
      key.bytesize.to_u64,
      value.to_unsafe,
      value.bytesize.to_u64
    )

    snapshot = LibWarthog.warthog_snapshot_open(handle)
    snapshot.should_not be_nil

    buffer = Bytes.new(1024)
    out_len = 0_u64

    snapshot_get_result = LibWarthog.warthog_snapshot_get(
      handle,
      snapshot,
      key.to_unsafe,
      key.bytesize.to_u64,
      buffer.to_unsafe,
      buffer.size.to_u64,
      pointerof(out_len)
    )

    (snapshot_get_result == 0 || snapshot_get_result == 1).should be_true

    LibWarthog.warthog_snapshot_close(handle, snapshot)
    LibWarthog.warthog_close(handle)
  end

  it "iterates over key-value pairs" do
    db_path = "/tmp/test_warthog_db_#{Time.utc.to_unix_ms}"
    handle = LibWarthog.warthog_open(
      db_path.to_unsafe,
      1024_u32 * 1024_u32 * 10_u32,
      0.7,
      10000_u32
    )
    handle.should_not be_nil

    entries = {
      "key1" => "value1",
      "key2" => "value2",
      "key3" => "value3",
    }

    entries.each do |key, value|
      LibWarthog.warthog_put(
        handle,
        key.to_unsafe,
        key.bytesize.to_u64,
        value.to_unsafe,
        value.bytesize.to_u64
      )
    end

    iter = LibWarthog.warthog_iter_open(handle)
    iter.should_not be_nil

    found_entries = {} of String => String
    key_buffer = Bytes.new(1024)
    val_buffer = Bytes.new(1024)
    key_len = 0_u64
    val_len = 0_u64

    loop do
      result = LibWarthog.warthog_iter_next(
        iter,
        key_buffer.to_unsafe,
        key_buffer.size.to_u64,
        pointerof(key_len),
        val_buffer.to_unsafe,
        val_buffer.size.to_u64,
        pointerof(val_len)
      )

      break if result == 1
      result.should eq(0)

      key = String.new(key_buffer[0, key_len])
      val = String.new(val_buffer[0, val_len])
      found_entries[key] = val
    end

    found_entries.should eq(entries)

    LibWarthog.warthog_iter_close(iter)
    LibWarthog.warthog_close(handle)
  end

  it "opens and closes snapshot iterators" do
    db_path = "/tmp/test_warthog_snapshot_iter_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    handle = LibWarthog.warthog_open(
      db_path.to_unsafe,
      1024_u32 * 1024_u32,
      0.7,
      10000_u32
    )
    handle.should_not be_nil

    entries = {
      "key1" => "value1",
      "key2" => "value2",
      "key3" => "value3",
    }

    entries.each do |key, value|
      LibWarthog.warthog_put(
        handle,
        key.to_unsafe,
        key.bytesize.to_u64,
        value.to_unsafe,
        value.bytesize.to_u64
      )
    end

    snapshot = LibWarthog.warthog_snapshot_open(handle)
    snapshot.should_not be_nil

    iter = LibWarthog.warthog_snapshot_iter_open(handle, snapshot)
    iter.should_not be_nil

    key_buffer = Bytes.new(1024)
    val_buffer = Bytes.new(1024)
    key_len = 0_u64
    val_len = 0_u64

    loop do
      result = LibWarthog.warthog_iter_next(
        iter,
        key_buffer.to_unsafe,
        key_buffer.size.to_u64,
        pointerof(key_len),
        val_buffer.to_unsafe,
        val_buffer.size.to_u64,
        pointerof(val_len)
      )

      break if result == 1
    end

    LibWarthog.warthog_iter_close(iter)
    LibWarthog.warthog_snapshot_close(handle, snapshot)
    LibWarthog.warthog_close(handle)
  end
end
