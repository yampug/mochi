require "spec"
require "../../src/sorbet/sorbet"

# Basic smoke tests that verify the library loads and bindings work
# without actually running full Sorbet typechecking (which requires proper config)
describe "Sorbet Library Smoke Tests", tags: "sorbet" do
  describe "library loading" do
    it "loads the libsorbet library" do
      # If we get this far, the library loaded successfully
      true.should be_true
    end
  end

  describe "type definitions" do
    it "can create a Diagnostic" do
      diag = Sorbet::Diagnostic.new(
        file: "test.rb",
        line: 0,
        column: 0,
        end_line: 0,
        end_column: 1,
        message: "test",
        severity: "error"
      )
      diag.should be_a(Sorbet::Diagnostic)
    end

    it "can create a TypecheckResult" do
      result = Sorbet::TypecheckResult.new
      result.should be_a(Sorbet::TypecheckResult)
    end
  end

  describe "Diagnostic creation" do
    it "creates a diagnostic with all fields" do
      diag = Sorbet::Diagnostic.new(
        file: "test.rb",
        line: 5,
        column: 10,
        end_line: 5,
        end_column: 20,
        message: "Test error",
        severity: "error",
        code: "1234"
      )

      diag.file.should eq("test.rb")
      diag.line.should eq(5)
      diag.column.should eq(10)
      diag.end_line.should eq(5)
      diag.end_column.should eq(20)
      diag.message.should eq("Test error")
      diag.severity.should eq("error")
      diag.code.should eq("1234")
    end

    it "creates a diagnostic without code" do
      diag = Sorbet::Diagnostic.new(
        file: "test.rb",
        line: 0,
        column: 0,
        end_line: 0,
        end_column: 5,
        message: "Warning",
        severity: "warning"
      )

      diag.code.should be_nil
      diag.severity.should eq("warning")
    end
  end

  describe "TypecheckResult" do
    it "creates an empty result" do
      result = Sorbet::TypecheckResult.new
      result.diagnostics.should be_empty
      result.errors.should be_empty
      result.warnings.should be_empty
      result.success?.should be_true
    end

    it "adds diagnostics" do
      result = Sorbet::TypecheckResult.new

      error = Sorbet::Diagnostic.new(
        file: "test.rb",
        line: 0,
        column: 0,
        end_line: 0,
        end_column: 5,
        message: "Error",
        severity: "error"
      )

      warning = Sorbet::Diagnostic.new(
        file: "test.rb",
        line: 1,
        column: 0,
        end_line: 1,
        end_column: 5,
        message: "Warning",
        severity: "warning"
      )

      result.add(error)
      result.add(warning)

      result.diagnostics.size.should eq(2)
      result.errors.size.should eq(1)
      result.warnings.size.should eq(1)
      result.success?.should be_false
    end

    it "merges results" do
      result1 = Sorbet::TypecheckResult.new
      result2 = Sorbet::TypecheckResult.new

      diag1 = Sorbet::Diagnostic.new(
        file: "test1.rb",
        line: 0,
        column: 0,
        end_line: 0,
        end_column: 5,
        message: "Error 1",
        severity: "error"
      )

      diag2 = Sorbet::Diagnostic.new(
        file: "test2.rb",
        line: 0,
        column: 0,
        end_line: 0,
        end_column: 5,
        message: "Error 2",
        severity: "error"
      )

      result1.add(diag1)
      result2.add(diag2)

      result1.merge(result2)

      result1.diagnostics.size.should eq(2)
      result1.errors.size.should eq(2)
    end
  end

  describe "JSON parsing" do
    it "parses diagnostic from JSON" do
      json_str = %(
        {
          "range": {
            "start": {"line": 10, "character": 5},
            "end": {"line": 10, "character": 15}
          },
          "severity": 1,
          "message": "Undefined variable",
          "code": "7003"
        }
      )

      json = JSON.parse(json_str)
      diag = Sorbet::Diagnostic.from_json(json, "file:///path/to/test.rb")

      diag.file.should eq("/path/to/test.rb")
      diag.line.should eq(10)
      diag.column.should eq(5)
      diag.end_line.should eq(10)
      diag.end_column.should eq(15)
      diag.message.should eq("Undefined variable")
      diag.severity.should eq("error")
      diag.code.should eq("7003")
    end

    it "maps severity levels correctly" do
      # Test each severity level
      severities = {
        1 => "error",
        2 => "warning",
        3 => "information",
        4 => "hint",
      }

      severities.each do |num, name|
        json_str = %(
          {
            "range": {
              "start": {"line": 0, "character": 0},
              "end": {"line": 0, "character": 1}
            },
            "severity": #{num},
            "message": "Test"
          }
        )

        json = JSON.parse(json_str)
        diag = Sorbet::Diagnostic.from_json(json, "file:///test.rb")
        diag.severity.should eq(name)
      end
    end

    it "handles missing severity" do
      json_str = %(
        {
          "range": {
            "start": {"line": 0, "character": 0},
            "end": {"line": 0, "character": 1}
          },
          "message": "Test"
        }
      )

      json = JSON.parse(json_str)
      diag = Sorbet::Diagnostic.from_json(json, "file:///test.rb")

      # Should default to error when severity is missing
      diag.severity.should eq("error")
    end
  end
end
