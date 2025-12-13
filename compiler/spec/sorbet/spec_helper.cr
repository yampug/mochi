require "spec"
require "../../src/sorbet/sorbet"

module SorbetSpecHelper
  # Helper method to create a temporary Ruby file for testing
  def self.create_temp_file(content : String, filename : String? = nil) : String
    filename ||= "test_#{Random.rand(1000000)}.rb"
    File.write(filename, content)
    filename
  end

  # Helper method to clean up temporary files
  def self.cleanup_file(filename : String)
    File.delete(filename) if File.exists?(filename)
  rescue
    # Ignore cleanup errors
  end

  # Common Ruby code samples for testing
  module CodeSamples
    def self.simple_class
      <<-RUBY
      class TestClass
        def self.hello
          "Hello World"
        end

        def instance_method
          @value = 42
        end
      end

      TestClass.hello
      RUBY
    end

    def self.class_with_error
      <<-RUBY
      class TestClass
        def self.method_with_error
          undefined_method_call
        end
      end

      TestClass.method_with_error
      RUBY
    end

    def self.user_class
      <<-RUBY
      class User
        attr_reader :name, :email

        def initialize(name, email)
          @name = name
          @email = email
        end

        def greet
          "Hello, \#{@name}!"
        end
      end
      RUBY
    end

    def self.product_class
      <<-RUBY
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
    end

    def self.order_class
      <<-RUBY
      class Order
        def initialize(user, products)
          @user = user
          @products = products
        end

        def total
          @products.sum(&:price)
        end

        def user_name
          @user.name
        end
      end
      RUBY
    end

    def self.class_with_type_error
      <<-RUBY
      class Calculator
        def add(a, b)
          a + b
        end

        def broken_add
          # This will cause a type error in strict mode
          1 + "string"
        end
      end
      RUBY
    end

    def self.class_with_undefined_variable
      <<-RUBY
      class BuggyClass
        def method_with_undefined_var
          result = undefined_variable + 10
          result
        end
      end
      RUBY
    end

    def self.class_with_undefined_method
      <<-RUBY
      class AnotherBuggyClass
        def call_undefined_method
          this_method_does_not_exist(42)
        end
      end
      RUBY
    end

    def self.empty_class
      <<-RUBY
      class EmptyClass
      end
      RUBY
    end

    def self.class_with_inheritance
      <<-RUBY
      class Animal
        def speak
          "Some sound"
        end
      end

      class Dog < Animal
        def speak
          "Woof!"
        end

        def wag_tail
          "Wagging tail"
        end
      end
      RUBY
    end

    def self.module_and_class
      <<-RUBY
      module Greeting
        def say_hello
          "Hello from module!"
        end
      end

      class Greeter
        include Greeting
      end
      RUBY
    end
  end

  # Helper to create a session with common defaults
  def self.create_session(multi_threaded : Bool = false, num_threads : Int32 = 2) : Sorbet::Session
    Sorbet::Session.new(
      root_dir: ".",
      multi_threaded: multi_threaded,
      num_threads: num_threads
    )
  end

  # Helper to run a test with automatic session cleanup
  def self.with_session(multi_threaded : Bool = false, &block : Sorbet::Session ->)
    session = create_session(multi_threaded)
    begin
      yield session
    ensure
      session.close if session && session.open?
    end
  end

  # Helper to assert diagnostic count
  def self.assert_diagnostic_count(result : Sorbet::TypecheckResult, errors : Int32? = nil, warnings : Int32? = nil)
    if errors
      result.errors.size.should eq(errors), "Expected #{errors} errors, got #{result.errors.size}"
    end
    if warnings
      result.warnings.size.should eq(warnings), "Expected #{warnings} warnings, got #{result.warnings.size}"
    end
  end

  # Helper to print diagnostics for debugging
  def self.print_diagnostics(result : Sorbet::TypecheckResult)
    puts "\n=== Diagnostics ==="
    if result.diagnostics.empty?
      puts "No diagnostics"
    else
      result.diagnostics.each do |diag|
        puts diag
      end
    end
    puts "===================\n"
  end
end
