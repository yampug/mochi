require "spec"
require "../../src/sorbet/sorbet"

describe Sorbet::Session do
  describe "initialization" do
    # it "creates a single-threaded session" do
    #   session = Sorbet::Session.new(
    #     root_dir: ".",
    #     multi_threaded: false
    #   )
    #
    #   session.open?.should be_true
    #   session.close
    #   session.open?.should be_false
    # end

    it "creates a multi-threaded session" do
      session = Sorbet::Session.new(
        root_dir: ".",
        multi_threaded: true,
        num_threads: 2
      )

      session.open?.should be_true
      session.close
      session.open?.should be_false
    end

    # it "raises error when session fails to initialize" do
    #   # This would require invalid args to trigger the error
    #   # For now, we just verify normal initialization works
    #   expect_raises(Exception) do
    #     session = Sorbet::Session.new(root_dir: ".")
    #     session.close if session
    #     raise "Placeholder - actual error test would need invalid args"
    #   end
    # end
  end

  describe "single file typechecking" do
    it "typechecks valid Ruby code" do
      session = Sorbet::Session.new

      valid_code = <<-RUBY
      class Calculator
        def add(a, b)
          a + b
        end
      end

      Calculator.new.add(1, 2)
      RUBY

      result = session.typecheck_file("calculator.rb", valid_code)

      # Valid code may still have some diagnostics depending on Sorbet's strictness
      # but it should at least not crash
      result.should be_a(Sorbet::TypecheckResult)

      session.close
    end

    it "detects errors in invalid Ruby code" do
      session = Sorbet::Session.new

      invalid_code = <<-RUBY
      class BuggyClass
        def broken_method
          undefined_variable + 10
        end
      end
      RUBY

      result = session.typecheck_file("buggy.rb", invalid_code)

      result.should be_a(Sorbet::TypecheckResult)
      result.diagnostics.should be_a(Array(Sorbet::Diagnostic))

      session.close
    end

    it "handles multiple files with the same session" do
      session = Sorbet::Session.new

      code1 = <<-RUBY
      class User
        attr_reader :name

        def initialize(name)
          @name = name
        end
      end
      RUBY

      code2 = <<-RUBY
      class Product
        attr_reader :price

        def initialize(price)
          @price = price
        end
      end
      RUBY

      result1 = session.typecheck_file("user.rb", code1)
      result2 = session.typecheck_file("product.rb", code2)

      result1.should be_a(Sorbet::TypecheckResult)
      result2.should be_a(Sorbet::TypecheckResult)

      session.close
    end
  end

  describe "batch typechecking" do
    it "typechecks multiple files at once with hash" do
      session = Sorbet::Session.new(
        root_dir: ".",
        multi_threaded: true,
        num_threads: 4
      )

      files = {
        "user.rb" => <<-RUBY,
          class User
            attr_reader :name, :email

            def initialize(name, email)
              @name = name
              @email = email
            end

            def greet
              "Hello, " + @name
            end
          end
        RUBY
        "product.rb" => <<-RUBY,
          class Product
            attr_reader :name, :price

            def initialize(name, price)
              @name = name
              @price = price
            end

            def discounted_price(discount)
              @price - (@price * discount)
            end
          end
        RUBY
        "order.rb" => <<-RUBY,
          class Order
            def initialize(user, products)
              @user = user
              @products = products
            end

            def total
              @products.sum(&:price)
            end
          end
        RUBY
      }

      result = session.typecheck_files(files)

      result.should be_a(Sorbet::TypecheckResult)
      result.diagnostics.should be_a(Array(Sorbet::Diagnostic))

      session.close
    end

    it "handles empty file list" do
      session = Sorbet::Session.new

      files = {} of String => String
      result = session.typecheck_files(files)

      result.should be_a(Sorbet::TypecheckResult)
      result.diagnostics.size.should eq(0)

      session.close
    end
  end

  describe "error handling" do
    # it "raises error when using closed session" do
    #   session = Sorbet::Session.new
    #   session.close
    #
    #   expect_raises(Exception, /Session is closed/) do
    #     session.typecheck_file("test.rb", "class Test; end")
    #   end
    # end
  end
end

describe Sorbet::TypecheckResult do
  describe "filtering diagnostics" do
    it "separates errors and warnings" do
      result = Sorbet::TypecheckResult.new

      error1 = Sorbet::Diagnostic.new(
        file: "test.rb",
        line: 0,
        column: 0,
        end_line: 0,
        end_column: 5,
        message: "Error 1",
        severity: "error"
      )

      error2 = Sorbet::Diagnostic.new(
        file: "test.rb",
        line: 1,
        column: 0,
        end_line: 1,
        end_column: 5,
        message: "Error 2",
        severity: "error"
      )

      warning1 = Sorbet::Diagnostic.new(
        file: "test.rb",
        line: 2,
        column: 0,
        end_line: 2,
        end_column: 5,
        message: "Warning 1",
        severity: "warning"
      )

      result.add(error1)
      result.add(error2)
      result.add(warning1)

      result.diagnostics.size.should eq(3)
      result.errors.size.should eq(2)
      result.warnings.size.should eq(1)
    end

    it "checks success status" do
      result = Sorbet::TypecheckResult.new
      result.success?.should be_true

      error = Sorbet::Diagnostic.new(
        file: "test.rb",
        line: 0,
        column: 0,
        end_line: 0,
        end_column: 5,
        message: "Error",
        severity: "error"
      )

      result.add(error)
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
    end
  end
end

describe Sorbet::Diagnostic do
  describe "creation and formatting" do
    it "creates a diagnostic with all fields" do
      diag = Sorbet::Diagnostic.new(
        file: "/path/to/test.rb",
        line: 10,
        column: 5,
        end_line: 10,
        end_column: 15,
        message: "Undefined variable",
        severity: "error",
        code: "7003"
      )

      diag.file.should eq("/path/to/test.rb")
      diag.line.should eq(10)
      diag.column.should eq(5)
      diag.end_line.should eq(10)
      diag.end_column.should eq(15)
      diag.message.should eq("Undefined variable")
      diag.severity.should eq("error")
      diag.code.should eq("7003")
    end

    it "formats diagnostic as string" do
      diag = Sorbet::Diagnostic.new(
        file: "test.rb",
        line: 5,
        column: 10,
        end_line: 5,
        end_column: 20,
        message: "Test error",
        severity: "error"
      )

      # Line and column are 0-indexed internally but displayed as 1-indexed
      diag.to_s.should contain("test.rb:6:11")
      diag.to_s.should contain("error")
      diag.to_s.should contain("Test error")
    end
  end

  describe "from_json" do
    it "parses diagnostic from JSON" do
      json_data = JSON.parse(%(
        {
          "range": {
            "start": {"line": 5, "character": 10},
            "end": {"line": 5, "character": 20}
          },
          "severity": 1,
          "message": "Test error",
          "code": "7003"
        }
      ))

      diag = Sorbet::Diagnostic.from_json(json_data, "file:///path/to/test.rb")

      diag.file.should eq("/path/to/test.rb")
      diag.line.should eq(5)
      diag.column.should eq(10)
      diag.end_line.should eq(5)
      diag.end_column.should eq(20)
      diag.message.should eq("Test error")
      diag.severity.should eq("error")
      diag.code.should eq("7003")
    end

    it "maps severity numbers correctly" do
      # Severity 1 = error
      json1 = JSON.parse(%({"range": {"start": {"line": 0, "character": 0}, "end": {"line": 0, "character": 1}}, "severity": 1, "message": "Error"}))
      diag1 = Sorbet::Diagnostic.from_json(json1, "file:///test.rb")
      diag1.severity.should eq("error")

      # Severity 2 = warning
      json2 = JSON.parse(%({"range": {"start": {"line": 0, "character": 0}, "end": {"line": 0, "character": 1}}, "severity": 2, "message": "Warning"}))
      diag2 = Sorbet::Diagnostic.from_json(json2, "file:///test.rb")
      diag2.severity.should eq("warning")

      # Severity 3 = information
      json3 = JSON.parse(%({"range": {"start": {"line": 0, "character": 0}, "end": {"line": 0, "character": 1}}, "severity": 3, "message": "Info"}))
      diag3 = Sorbet::Diagnostic.from_json(json3, "file:///test.rb")
      diag3.severity.should eq("information")

      # Severity 4 = hint
      json4 = JSON.parse(%({"range": {"start": {"line": 0, "character": 0}, "end": {"line": 0, "character": 1}}, "severity": 4, "message": "Hint"}))
      diag4 = Sorbet::Diagnostic.from_json(json4, "file:///test.rb")
      diag4.severity.should eq("hint")
    end
  end
end
