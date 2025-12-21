require "spec"
require "../spec_data_loader"
require "../../src/tree-sitter/method_body_extractor"

describe TreeSitter::MethodBodyExtractor do
  describe "extract_method_bodies" do
    it "extracts simple method with no parameters" do
      code = SpecDataLoader.load("ruby/methods_simple.rb")
      methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 1
      methods.has_key?("render").should be_true

      render_method = methods["render"]
      render_method.name.should eq "render"
      render_method.class_name.should eq "MyComponent"
      render_method.parameters.should eq [] of String
      render_method.body.should eq ["  def render", "    puts \"Hello\"", "  end"]
    end

    it "extracts method with parameters" do
      code = SpecDataLoader.load("ruby/methods_with_params.rb")
      methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 1
      methods.has_key?("greet").should be_true

      greet_method = methods["greet"]
      greet_method.name.should eq "greet"
      greet_method.parameters.should eq ["name", "age"]
    end

    it "extracts multiple methods" do
      code = SpecDataLoader.load("ruby/methods_multiple.rb")
      methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 3
      methods.has_key?("first_method").should be_true
      methods.has_key?("second_method").should be_true
      methods.has_key?("third_method").should be_true

      methods["first_method"].parameters.should eq [] of String
      methods["second_method"].parameters.should eq ["arg"]
      methods["third_method"].parameters.should eq [] of String
    end

    it "handles method with nested if statement" do
      code = SpecDataLoader.load("ruby/methods_nested_if.rb")
      methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 1
      check_method = methods["check_value"]
      check_method.parameters.should eq ["value"]
      check_method.body.size.should eq 7
      check_method.body[0].should eq "  def check_value(value)"
      check_method.body[6].should eq "  end"
    end

    it "handles method with loop" do
      code = SpecDataLoader.load("ruby/methods_with_loop.rb")
      methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 1
      iterate_method = methods["iterate"]
      iterate_method.parameters.should eq ["items"]
      iterate_method.body.size.should eq 5
      iterate_method.body[0].should eq "  def iterate(items)"
      iterate_method.body[1].should eq "    items.each do |item|"
      iterate_method.body[2].should eq "      puts item"
      iterate_method.body[4].should eq "  end"
    end

    it "handles empty method" do
      code = SpecDataLoader.load("ruby/methods_empty.rb")
      methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 1
      empty_method = methods["empty_method"]
      empty_method.parameters.should eq [] of String
      empty_method.body.should eq ["  def empty_method", "  end"]
    end

    it "extracts method with default parameters" do
      code = SpecDataLoader.load("ruby/methods_default_params.rb")
      methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 1
      configure_method = methods["configure"]
      configure_method.parameters.should eq ["name", "enabled = true"]
    end

    it "returns empty hash when no methods found" do
      code = <<-RUBY
      class MyComponent
        @name = "test"
      end
      RUBY
      methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 0
    end

    it "preserves indentation in method body" do
      code = SpecDataLoader.load("ruby/methods_nested_if.rb")
      methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, "MyComponent")

      check_method = methods["check_value"]
      check_method.body[1].should eq "    if value > 0"
      check_method.body[2].should eq "      puts \"positive\""
    end

    it "returns empty hash for non-existent class" do
      code = SpecDataLoader.load("ruby/methods_simple.rb")
      methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, "NonExistentClass")

      methods.size.should eq 0
    end

    it "handles namespaced class names" do
      code = <<-RUBY
      module MyApp
        class MyComponent
          def render
            puts "Hello"
          end
        end
      end
      RUBY
      methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 1
      methods.has_key?("render").should be_true
    end

    it "extracts method with splat parameters" do
      code = <<-RUBY
      class MyComponent
        def process(*args)
          puts args
        end
      end
      RUBY
      methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 1
      methods["process"].parameters.should eq ["*args"]
    end

    it "extracts method with keyword parameters" do
      code = <<-RUBY
      class MyComponent
        def configure(name:, enabled: true)
          @name = name
        end
      end
      RUBY
      methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 1
      configure_method = methods["configure"]
      configure_method.parameters.size.should eq 2
    end

    it "extracts method with block parameter" do
      code = <<-RUBY
      class MyComponent
        def execute(&block)
          block.call
        end
      end
      RUBY
      methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 1
      methods["execute"].parameters.should eq ["&block"]
    end
  end
end
