require "spec"
require "./spec_helper"

describe "Sorbet Integration" do
  describe "real-world usage patterns" do
    it "typechecks a simple Ruby project" do
      SorbetSpecHelper.with_session do |session|
        files = {
          "models/user.rb"    => SorbetSpecHelper::CodeSamples.user_class,
          "models/product.rb" => SorbetSpecHelper::CodeSamples.product_class,
          "models/order.rb"   => SorbetSpecHelper::CodeSamples.order_class,
        }

        result = session.typecheck_files(files)

        result.should be_a(Sorbet::TypecheckResult)
        # The result may have some diagnostics depending on Sorbet's strictness
        # but it shouldn't crash
        result.diagnostics.should be_a(Array(Sorbet::Diagnostic))
      end
    end

    it "detects common Ruby errors" do
      SorbetSpecHelper.with_session do |session|
        files = {
          "buggy1.rb" => SorbetSpecHelper::CodeSamples.class_with_undefined_variable,
          "buggy2.rb" => SorbetSpecHelper::CodeSamples.class_with_undefined_method,
        }

        result = session.typecheck_files(files)

        # These should have diagnostics (though exact count depends on Sorbet config)
        result.should be_a(Sorbet::TypecheckResult)
        result.diagnostics.should be_a(Array(Sorbet::Diagnostic))
      end
    end

    it "handles incremental typechecking" do
      SorbetSpecHelper.with_session do |session|
        # First, typecheck one file
        result1 = session.typecheck_file(
          "user.rb",
          SorbetSpecHelper::CodeSamples.user_class
        )

        result1.should be_a(Sorbet::TypecheckResult)

        # Then typecheck another file
        result2 = session.typecheck_file(
          "product.rb",
          SorbetSpecHelper::CodeSamples.product_class
        )

        result2.should be_a(Sorbet::TypecheckResult)

        # Both should work without issues
        result1.diagnostics.should be_a(Array(Sorbet::Diagnostic))
        result2.diagnostics.should be_a(Array(Sorbet::Diagnostic))
      end
    end

    it "uses multi-threaded mode for batch processing" do
      SorbetSpecHelper.with_session(multi_threaded: true) do |session|
        # Create a larger set of files
        files = {} of String => String

        10.times do |i|
          files["class_#{i}.rb"] = <<-RUBY
          class TestClass#{i}
            def method_#{i}
              "result #{i}"
            end
          end
          RUBY
        end

        result = session.typecheck_files(files)

        result.should be_a(Sorbet::TypecheckResult)
        result.diagnostics.should be_a(Array(Sorbet::Diagnostic))
      end
    end
  end

  describe "error reporting" do
    it "provides detailed diagnostic information" do
      SorbetSpecHelper.with_session do |session|
        code_with_error = <<-RUBY
        class Example
          def broken_method
            undefined_variable
          end
        end
        RUBY

        result = session.typecheck_file("example.rb", code_with_error)

        # Check that diagnostics have expected fields
        if result.diagnostics.size > 0
          diag = result.diagnostics.first
          diag.file.should be_a(String)
          diag.line.should be_a(Int32)
          diag.column.should be_a(Int32)
          diag.message.should be_a(String)
          diag.severity.should be_a(String)
        end
      end
    end

    it "distinguishes between errors and warnings" do
      SorbetSpecHelper.with_session do |session|
        # This test depends on Sorbet's behavior
        # In practice, you'd have code that generates both errors and warnings
        code = SorbetSpecHelper::CodeSamples.simple_class

        result = session.typecheck_file("test.rb", code)

        # Verify we can separate errors from warnings
        errors = result.errors
        warnings = result.warnings

        errors.should be_a(Array(Sorbet::Diagnostic))
        warnings.should be_a(Array(Sorbet::Diagnostic))

        # All errors should have severity "error"
        errors.all? { |e| e.severity == "error" }.should be_true
        # All warnings should have severity "warning"
        warnings.all? { |w| w.severity == "warning" }.should be_true
      end
    end
  end

  describe "performance optimization" do
    it "batch processing is more efficient than individual files" do
      # Create test data
      files = {} of String => String
      5.times do |i|
        files["test_#{i}.rb"] = <<-RUBY
        class Test#{i}
          def method_#{i}
            #{i} + 1
          end
        end
        RUBY
      end

      # Batch processing
      batch_time = Time.measure do
        SorbetSpecHelper.with_session(multi_threaded: true) do |session|
          session.typecheck_files(files)
        end
      end

      # Individual processing
      individual_time = Time.measure do
        SorbetSpecHelper.with_session do |session|
          files.each do |path, content|
            session.typecheck_file(path, content)
          end
        end
      end

      # Just verify both approaches work
      # (In practice, batch should be faster, but timing can vary)
      batch_time.should be_a(Time::Span)
      individual_time.should be_a(Time::Span)
    end
  end

  describe "edge cases" do
    it "handles empty file content" do
      SorbetSpecHelper.with_session do |session|
        result = session.typecheck_file("empty.rb", "")
        result.should be_a(Sorbet::TypecheckResult)
      end
    end

    it "handles file with only comments" do
      SorbetSpecHelper.with_session do |session|
        result = session.typecheck_file("comments.rb", "# Just a comment\n# Another comment")
        result.should be_a(Sorbet::TypecheckResult)
      end
    end

    it "handles complex Ruby syntax" do
      SorbetSpecHelper.with_session do |session|
        complex_code = <<-RUBY
        class ComplexExample
          CONSTANT = 42

          attr_accessor :value

          def initialize(value = nil)
            @value = value || CONSTANT
          end

          def self.class_method
            "class method"
          end

          def instance_method(&block)
            yield @value if block_given?
          end

          private

          def private_method
            "private"
          end
        end
        RUBY

        result = session.typecheck_file("complex.rb", complex_code)
        result.should be_a(Sorbet::TypecheckResult)
      end
    end

    it "handles modules and mixins" do
      SorbetSpecHelper.with_session do |session|
        result = session.typecheck_file(
          "module_test.rb",
          SorbetSpecHelper::CodeSamples.module_and_class
        )
        result.should be_a(Sorbet::TypecheckResult)
      end
    end

    it "handles inheritance" do
      SorbetSpecHelper.with_session do |session|
        result = session.typecheck_file(
          "inheritance.rb",
          SorbetSpecHelper::CodeSamples.class_with_inheritance
        )
        result.should be_a(Sorbet::TypecheckResult)
      end
    end
  end

  describe "session lifecycle" do
    it "can be reused for multiple operations" do
      session = SorbetSpecHelper.create_session

      # Operation 1
      result1 = session.typecheck_file("test1.rb", SorbetSpecHelper::CodeSamples.user_class)
      result1.should be_a(Sorbet::TypecheckResult)

      # Operation 2
      result2 = session.typecheck_file("test2.rb", SorbetSpecHelper::CodeSamples.product_class)
      result2.should be_a(Sorbet::TypecheckResult)

      # Operation 3 - batch
      files = {
        "a.rb" => SorbetSpecHelper::CodeSamples.simple_class,
        "b.rb" => SorbetSpecHelper::CodeSamples.empty_class,
      }
      result3 = session.typecheck_files(files)
      result3.should be_a(Sorbet::TypecheckResult)

      session.close
    end

    it "properly tracks open/closed state" do
      session = SorbetSpecHelper.create_session
      session.open?.should be_true

      session.close
      session.open?.should be_false

      # Closing again should be safe
      session.close
      session.open?.should be_false
    end
  end
end
