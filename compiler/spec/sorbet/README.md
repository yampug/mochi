# Sorbet Wrapper Specs

This directory contains the test suite for the Sorbet Crystal wrapper.

## Running the Tests

### Prerequisites

1. **Build the libsorbet library** (if not already done):
   ```bash
   ./scripts/sorbet_lib_build.bash
   ```

   This will build and copy `libsorbet.dylib` to `./fragments/libs/`

2. **Ensure Crystal is installed** (version 1.0 or later)

### Quick Start - Run Smoke Tests First

```bash
# Run quick smoke tests to verify setup
crystal spec compiler/spec/sorbet/smoke_spec.cr --link-flags="-L./fragments/libs"
```

If smoke tests pass, you're all set! ✅

### Run All Sorbet Specs

From the project root:

```bash
crystal spec compiler/spec/sorbet/*.cr --link-flags="-L./fragments/libs"
```

### Run Specific Spec Files

```bash
# Run smoke tests (fastest, no Sorbet initialization)
crystal spec compiler/spec/sorbet/smoke_spec.cr --link-flags="-L./fragments/libs"

# Run unit tests
crystal spec compiler/spec/sorbet/sorbet_spec.cr --link-flags="-L./fragments/libs"

# Run integration tests
crystal spec compiler/spec/sorbet/integration_spec.cr --link-flags="-L./fragments/libs"
```

### Run Specific Tests

```bash
# Run tests matching a pattern
crystal spec compiler/spec/sorbet/sorbet_spec.cr --link-flags="-L./fragments/libs" -e "single file"
```

## Test Structure

### `smoke_spec.cr` ⚡ Quick Tests
Basic smoke tests that verify the library loads and core functionality works:
- Library loading verification
- Type definitions (Diagnostic, TypecheckResult)
- JSON parsing for diagnostics
- Basic object creation and manipulation

**Run these first** to verify your setup!

### `sorbet_spec.cr` 🔍 Unit Tests
Core unit tests for the Sorbet wrapper classes:
- `Sorbet::Session` - Session initialization and lifecycle
- `Sorbet::TypecheckResult` - Result filtering and aggregation
- `Sorbet::Diagnostic` - Diagnostic creation and parsing

**Note:** These tests create actual Sorbet sessions and may require proper Sorbet configuration.

### `integration_spec.cr` 🚀 Integration Tests
Integration tests demonstrating real-world usage:
- Multi-file project typechecking
- Error detection and reporting
- Performance optimization with batch processing
- Edge cases and complex syntax

**Note:** These tests perform actual typechecking and may take longer to run.

### `spec_helper.cr` 🛠️ Test Utilities
Test utilities and helper methods:
- `SorbetSpecHelper.with_session` - Automatic session cleanup
- `SorbetSpecHelper::CodeSamples` - Reusable Ruby code samples
- Helper methods for creating temp files and assertions

## Writing New Tests

### Basic Test Structure

```crystal
require "spec"
require "./spec_helper"

describe "Feature Name" do
  it "does something specific" do
    SorbetSpecHelper.with_session do |session|
      result = session.typecheck_file("test.rb", "class Test; end")
      result.should be_a(Sorbet::TypecheckResult)
    end
  end
end
```

### Using Code Samples

```crystal
it "typechecks a user class" do
  SorbetSpecHelper.with_session do |session|
    result = session.typecheck_file(
      "user.rb",
      SorbetSpecHelper::CodeSamples.user_class
    )
    result.success?.should be_true
  end
end
```

### Testing Error Cases

```crystal
it "detects undefined variables" do
  SorbetSpecHelper.with_session do |session|
    code = SorbetSpecHelper::CodeSamples.class_with_undefined_variable
    result = session.typecheck_file("buggy.rb", code)

    # Check that diagnostics were generated
    result.diagnostics.size.should be > 0
  end
end
```

## Debugging Tests

### Print Diagnostics

```crystal
it "debugs diagnostics" do
  SorbetSpecHelper.with_session do |session|
    result = session.typecheck_file("test.rb", code)
    SorbetSpecHelper.print_diagnostics(result)
  end
end
```

### Verbose Output

```bash
crystal spec compiler/spec/sorbet/*.cr --link-flags="-L./fragments/libs" --verbose
```

## Common Issues

### "library 'sorbet' not found"

Make sure you:
1. Built the library: `./scripts/sorbet_lib_build.bash`
2. Used the correct link flags: `--link-flags="-L./fragments/libs"`

### "Session is closed" errors

Make sure to use `SorbetSpecHelper.with_session` which automatically cleans up sessions, or manually call `session.close` in an `ensure` block.

### Tests are slow

Use multi-threaded mode for batch operations:
```crystal
SorbetSpecHelper.with_session(multi_threaded: true) do |session|
  # Your tests here
end
```

## Contributing

When adding new tests:
1. Use descriptive test names
2. Follow the existing test structure
3. Add code samples to `spec_helper.cr` if they'll be reused
4. Clean up resources (sessions, temp files) properly
5. Run all tests before committing

## CI Integration

To run these tests in CI:

```yaml
- name: Build libsorbet
  run: ./scripts/sorbet_lib_build.bash

- name: Run Sorbet specs
  run: crystal spec compiler/spec/sorbet/*.cr --link-flags="-L./fragments/libs"
```
