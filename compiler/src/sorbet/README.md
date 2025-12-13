# Sorbet Integration for Mochi

This directory contains the Crystal wrapper for the Sorbet C API, enabling Mochi to perform static type checking on Ruby codebases.

## Overview

The Sorbet wrapper provides a clean, idiomatic Crystal interface to the Sorbet type checker, built on top of the Sorbet LSP (Language Server Protocol) implementation.

## Features

- **Single-file typechecking** - Check individual Ruby files
- **Batch typechecking** - Efficiently check multiple files at once
- **Multi-threaded mode** - Faster checking for large codebases
- **Structured diagnostics** - Get detailed error and warning information
- **Memory safe** - Automatic cleanup of C resources
- **LSP-based** - Uses Sorbet's battle-tested LSP implementation

## Installation

### 1. Build the libsorbet library

The wrapper requires the libsorbet C library. Use the provided build script:

```bash
# From the mochi root directory
./scripts/sorbet_lib_build.bash

# Or for a specific platform
./scripts/sorbet_lib_build.bash --platform macos
./scripts/sorbet_lib_build.bash --platform linux

# Force rebuild
./scripts/sorbet_lib_build.bash --rebuild
```

This will:
1. Build libsorbet from the adjacent `../sorbet` repository
2. Copy the library to `fragments/libs/`

### 2. Use in your Crystal code

```crystal
require "./compiler/src/sorbet/sorbet"

# When building, link with the library
# crystal build -L./fragments/libs your_file.cr
```

## Usage

### Basic Example

```crystal
require "./compiler/src/sorbet/sorbet"

# Create a Sorbet session
session = Sorbet::Session.new

# Typecheck a file
result = session.typecheck_file("example.rb", ruby_code)

# Check results
if result.success?
  puts "No errors!"
else
  result.errors.each do |error|
    puts error
  end
end

# Clean up
session.close
```

### Batch Typechecking

```crystal
# Create a multi-threaded session for better performance
session = Sorbet::Session.new(
  root_dir: ".",
  multi_threaded: true,
  num_threads: 4
)

# Typecheck multiple files
files = {
  "user.rb" => File.read("user.rb"),
  "product.rb" => File.read("product.rb"),
  "order.rb" => File.read("order.rb")
}

result = session.typecheck_files(files)

puts "Found #{result.errors.size} errors"
puts "Found #{result.warnings.size} warnings"

session.close
```

### Typechecking from File Paths

```crystal
session = Sorbet::Session.new

# Pass file paths - content will be read automatically
files = Dir.glob("app/**/*.rb")
result = session.typecheck_files(files)

result.diagnostics.each do |diag|
  puts "#{diag.file}:#{diag.line}:#{diag.column}: #{diag.message}"
end

session.close
```

## API Reference

### `Sorbet::Session`

The main class for interacting with Sorbet.

#### Constructor

```crystal
Session.new(
  root_dir : String = ".",
  multi_threaded : Bool = false,
  num_threads : Int32 = 2,
  extra_args : Array(String) = [] of String
)
```

- `root_dir` - Root directory of the Ruby project
- `multi_threaded` - Use multi-threaded mode (recommended for >100 files)
- `num_threads` - Number of worker threads
- `extra_args` - Additional Sorbet CLI arguments (e.g., `["--typed", "strict"]`)

#### Methods

- `typecheck_file(file_path : String, content : String? = nil) : TypecheckResult`
  - Typecheck a single file
  - If `content` is nil, reads from disk

- `typecheck_files(files : Hash(String, String) | Array(String)) : TypecheckResult`
  - Typecheck multiple files
  - Accepts either a hash of path => content or an array of paths

- `close`
  - Close the session and free resources
  - Called automatically when object is garbage collected

- `open? : Bool`
  - Check if the session is still open

### `Sorbet::TypecheckResult`

Result of a typecheck operation.

#### Properties

- `diagnostics : Array(Diagnostic)` - All diagnostics (errors, warnings, etc.)

#### Methods

- `errors : Array(Diagnostic)` - Only errors
- `warnings : Array(Diagnostic)` - Only warnings
- `success? : Bool` - True if no errors found

### `Sorbet::Diagnostic`

A single diagnostic message.

#### Properties

- `file : String` - File path
- `line : Int32` - Line number (0-indexed)
- `column : Int32` - Column number (0-indexed)
- `end_line : Int32` - End line number
- `end_column : Int32` - End column number
- `message : String` - Diagnostic message
- `severity : String` - One of: "error", "warning", "information", "hint"
- `code : String?` - Optional error code

## Performance Tips

1. **Use multi-threaded mode** for large codebases (>100 files)
2. **Batch typecheck** files instead of checking one by one
3. **Reuse sessions** - creating a session has overhead
4. **Use appropriate thread count** - typically 2-8 threads optimal

## Example

See `example.cr` for a complete working example:

```bash
# Build and run the example
cd compiler/src/sorbet
crystal build -L../../../fragments/libs example.cr
./example
```

## Integration with Mochi Compiler

The Sorbet integration is designed to be used during Mochi's compilation process to:

1. Validate Ruby code before transpilation
2. Generate more accurate type information for the JavaScript output
3. Provide better error messages to developers

Example integration:

```crystal
# In the compiler
session = Sorbet::Session.new(
  root_dir: project_root,
  multi_threaded: true,
  num_threads: 4
)

# Collect all Ruby files
ruby_files = collect_ruby_files(project_root)

# Typecheck all files
result = session.typecheck_files(ruby_files)

# Report errors
if !result.success?
  result.errors.each do |error|
    report_compilation_error(error)
  end
  exit(1)
end

# Continue with compilation...
session.close
```

## Troubleshooting

### Library not found error

If you get "library 'sorbet' not found":

1. Make sure you've built the library: `./scripts/sorbet_lib_build.bash`
2. Link with the library path: `crystal build -L./fragments/libs your_file.cr`
3. On macOS, check that the library exists: `ls -lh fragments/libs/libsorbet.dylib`

### Sorbet session fails to initialize

1. Check that your Ruby project has valid syntax
2. Ensure the `root_dir` points to a valid directory
3. Check for any Sorbet configuration issues

### Performance issues

1. Use `multi_threaded: true` for large codebases
2. Increase `num_threads` (try 4-8)
3. Use batch typechecking instead of individual file checks

## License

This code is part of the Mochi project and uses the same license.

The underlying Sorbet library is licensed under the Apache License 2.0.
