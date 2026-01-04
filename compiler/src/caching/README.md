# WarthogDB Crystal Bindings

Crystal bindings and high-level wrapper for WarthogDB.

## Files

- `warthog_bindings.cr` - Low-level C FFI bindings
- `warthogdb.cr` - High-level idiomatic Crystal wrapper

## Usage

### Basic Operations

```crystal
# Open a database
db = WarthogDB.open("/path/to/db")

# Put a key-value pair
db["key"] = "value"

# Get a value
value = db["key"]  # raises NotFoundError if missing
value = db["key"]? # returns nil if missing

# Delete a key
db.delete("key")

# Close the database
db.close
```

### Iteration

```crystal
# Iterate over all key-value pairs
db.each do |key, value|
  puts "#{key} => #{value}"
end
```

### Snapshots

```crystal
# Create a snapshot for consistent reads
snapshot = db.snapshot

# Read from snapshot
value = snapshot["key"]?

# Iterate over snapshot
snapshot.each do |key, value|
  puts "#{key} => #{value}"
end

snapshot.close
```

**Note:** Snapshots only capture data that has been "sealed" into read-only files, not data in the current active write file. This is by design for consistency.

### Binary Data

```crystal
# Works with Bytes too
key_bytes = Bytes[1, 2, 3, 4]
val_bytes = Bytes[5, 6, 7, 8]

db.put(key_bytes, val_bytes)
result = db.get(key_bytes)
```

### Configuration

```crystal
db = WarthogDB.new(
  path: "/path/to/db",
  max_file_size: 1024_u32 * 1024_u32 * 10_u32,  # 10MB
  compaction_threshold: 0.7,                      # 70%
  number_of_records: 10000_u32
)
```

## API Reference

### WarthogDB

- `initialize(path, max_file_size = 10MB, compaction_threshold = 0.7, number_of_records = 10000)`
- `self.open(...)` - Class method constructor
- `put(key : String | Bytes, value : String | Bytes)` - Store a key-value pair
- `get(key : String | Bytes) : String? | Bytes?` - Retrieve a value
- `[](key : String) : String` - Get value (raises if not found)
- `[]?(key : String) : String?` - Get value (returns nil if not found)
- `[]=(key : String, value : String)` - Store a value
- `delete(key : String | Bytes)` - Delete a key
- `each(&block)` - Iterate over key-value pairs
- `snapshot : Snapshot` - Create a snapshot
- `close` - Close the database

### WarthogDB::Snapshot

- `get(key : String | Bytes) : String? | Bytes?` - Get value from snapshot
- `[](key : String) : String` - Get value (raises if not found)
- `[]?(key : String) : String?` - Get value (returns nil if not found)
- `each(&block)` - Iterate over snapshot
- `close` - Close the snapshot

### Exceptions

- `WarthogDB::Error` - Base error class
- `WarthogDB::NotFoundError` - Key not found (raised by `[]`)
