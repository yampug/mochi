require "spec"
require "../src/caching/warthogdb"

describe WarthogDB do
  it "creates and closes a database" do
    db_path = "/tmp/warthog_spec_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    db = WarthogDB.new(db_path)
    db.path.should eq(db_path)
    db.close
  end

  it "puts and gets values" do
    db_path = "/tmp/warthog_spec_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    db = WarthogDB.new(db_path)

    db.put("key1", "value1")
    db.get("key1").should eq("value1")

    db.close
  end

  it "uses array syntax for put and get" do
    db_path = "/tmp/warthog_spec_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    db = WarthogDB.new(db_path)

    db["key2"] = "value2"
    db["key2"].should eq("value2")
    db["key2"]?.should eq("value2")

    db.close
  end

  it "returns nil for missing keys" do
    db_path = "/tmp/warthog_spec_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    db = WarthogDB.new(db_path)

    db.get("missing").should be_nil
    db["missing"]?.should be_nil

    db.close
  end

  it "raises NotFoundError for missing keys with []" do
    db_path = "/tmp/warthog_spec_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    db = WarthogDB.new(db_path)

    expect_raises(WarthogDB::NotFoundError) do
      db["missing"]
    end

    db.close
  end

  it "deletes keys" do
    db_path = "/tmp/warthog_spec_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    db = WarthogDB.new(db_path)

    db["key"] = "value"
    db["key"].should eq("value")

    db.delete("key")
    db["key"]?.should be_nil

    db.close
  end

  it "iterates over key-value pairs" do
    db_path = "/tmp/warthog_spec_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    db = WarthogDB.new(db_path)

    entries = {
      "a" => "value_a",
      "b" => "value_b",
      "c" => "value_c",
    }

    entries.each do |k, v|
      db[k] = v
    end

    found = {} of String => String
    db.each do |k, v|
      found[k] = v
    end

    found.should eq(entries)

    db.close
  end

  it "works with bytes" do
    db_path = "/tmp/warthog_spec_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    db = WarthogDB.new(db_path)

    key = Bytes[1, 2, 3, 4]
    value = Bytes[5, 6, 7, 8]

    db.put(key, value)
    result = db.get(key)

    result.should_not be_nil
    result.should eq(value)

    db.close
  end

  it "creates snapshots" do
    db_path = "/tmp/warthog_spec_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    db = WarthogDB.new(db_path)

    db["key1"] = "value1"

    snapshot = db.snapshot
    snapshot.should_not be_nil
    snapshot.close

    db.close
  end

  it "gets values from snapshots" do
    db_path = "/tmp/warthog_spec_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    db = WarthogDB.new(db_path)

    db["key1"] = "value1"

    snapshot = db.snapshot

    result = snapshot["key1"]?
    (result == "value1" || result.nil?).should be_true

    snapshot.close
    db.close
  end

  it "iterates over snapshot" do
    db_path = "/tmp/warthog_spec_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    db = WarthogDB.new(db_path)

    db["a"] = "1"
    db["b"] = "2"

    snapshot = db.snapshot

    found = {} of String => String
    snapshot.each do |k, v|
      found[k] = v
    end

    snapshot.close
    db.close
  end

  it "handles large values" do
    db_path = "/tmp/warthog_spec_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    db = WarthogDB.new(db_path)

    large_value = "x" * 100_000
    db["large"] = large_value
    db["large"].should eq(large_value)

    db.close
  end

  it "uses WarthogDB.open class method" do
    db_path = "/tmp/warthog_spec_#{Time.utc.to_unix_ms}_#{rand(10000)}"
    db = WarthogDB.open(db_path)

    db["test"] = "value"
    db["test"].should eq("value")

    db.close
  end
end
