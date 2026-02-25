require "spec"
require "../spec_data_loader"
require "../../src/ruby/ruby_understander"

def check_class_name(exp_name : String, code : String)
  name = RubyUnderstander.class_name(code)
  name.should eq(exp_name)
end

def extract_string_from_file(rb_file : String, method_name : String) : String?
  code = SpecDataLoader.load(rb_file)
  class_name = RubyUnderstander.class_name(code)
  methods = RubyUnderstander.extract_method_bodies(code, class_name)
  ruby_def = methods[method_name]?
  return nil unless ruby_def
  return RubyUnderstander.extract_raw_string_from_def_body(ruby_def.body, method_name)
end

describe RubyUnderstander do

  it "processes simple if condition" do
    code = SpecDataLoader.load("ruby/a_layout.rb")
    name = RubyUnderstander.class_name(code)
    name.should eq("ALayout")
  end

  it "class_name: inheritance" do
    code = <<-RUBY
    class MyClass < ParentClass
    end
    RUBY
    check_class_name("MyClass", code)
  end

  it "class_name: namespacing" do
    check_class_name("My::Nested::Class", "class My::Nested::Class")
  end

  it "class_name: extra spaces" do
    check_class_name("MyClass", "class   MyClass   ;   end")
  end

  it "class_name: comments" do
    check_class_name("MyClass", "class MyClass # comment")
  end

  it "class_name: embedded string" do
    check_class_name("", "\"class NotAClass\"")
  end

  it "class_name: class in a comment" do
    check_class_name("", "# class InComment ")
  end

  it "class_name: nested class" do
    check_class_name("A", "class A; class B; end; end")
  end

  describe "get_cmp_name" do
    it "extracts tag name with double quotes" do
      code = <<-RUBY
      class MyComponent
        @tag_name = "my-component"
      end
      RUBY
      result = RubyUnderstander.get_cmp_name(code, "MyComponent")
      result.should eq "my-component"
    end

    it "extracts tag name with single quotes" do
      code = <<-RUBY
      class MyComponent
        @tag_name = 'my-component'
      end
      RUBY
      result = RubyUnderstander.get_cmp_name(code, "MyComponent")
      result.should eq "my-component"
    end

    it "extracts tag name with extra whitespace" do
      code = <<-RUBY
      class MyComponent
        @tag_name    =    "my-component"
      end
      RUBY
      result = RubyUnderstander.get_cmp_name(code, "MyComponent")
      result.should eq "my-component"
    end

    it "extracts tag name without quotes" do
      code = <<-RUBY
      class MyComponent
        @tag_name = custom-tag
      end
      RUBY
      result = RubyUnderstander.get_cmp_name(code, "MyComponent")
      result.should eq "custom-tag"
    end

    it "returns nil when @tag_name not found" do
      code = <<-RUBY
      class MyComponent
        def initialize
        end
      end
      RUBY
      result = RubyUnderstander.get_cmp_name(code, "MyComponent")
      result.should be_nil
    end

    it "returns first match when multiple @tag_name exist" do
      code = <<-RUBY
      class MyComponent
        @tag_name = "first-component"
        @tag_name = "second-component"
      end
      RUBY
      result = RubyUnderstander.get_cmp_name(code, "MyComponent")
      result.should eq "first-component"
    end

    it "extracts tag name from middle of file" do
      code = <<-RUBY
      class MyComponent < BaseComponent
        def initialize
          @foo = "bar"
        end

        @tag_name = "middle-component"

        def render
          # implementation
        end
      end
      RUBY
      result = RubyUnderstander.get_cmp_name(code, "MyComponent")
      result.should eq "middle-component"
    end

    it "handles indented @tag_name" do
      code = <<-RUBY
      class MyComponent
          @tag_name = "indented-component"
      end
      RUBY
      result = RubyUnderstander.get_cmp_name(code, "MyComponent")
      result.should eq "indented-component"
    end

    it "extracts tag name with hyphens and underscores" do
      code = <<-RUBY
      class MyComponent
        @tag_name = "my-complex_component-name"
      end
      RUBY
      result = RubyUnderstander.get_cmp_name(code, "MyComponent")
      result.should eq "my-complex_component-name"
    end

    it "handles empty tag name value" do
      code = <<-RUBY
      class MyComponent
        @tag_name = ""
      end
      RUBY
      result = RubyUnderstander.get_cmp_name(code, "MyComponent")
      result.should eq ""
    end

    it "returns nil when @tag_name has no equals sign" do
      code = <<-RUBY
      class MyComponent
        @tag_name
      end
      RUBY
      result = RubyUnderstander.get_cmp_name(code, "MyComponent")
      result.should be_nil
    end

    it "ignores @tag_name in comments" do
      code = <<-RUBY
      class MyComponent
        # @tag_name = "commented-out"
        @tag_name = "actual-component"
      end
      RUBY
      result = RubyUnderstander.get_cmp_name(code, "MyComponent")
      result.should eq "actual-component"
    end

    it "extracts tag name with namespace syntax" do
      code = <<-RUBY
      class MyComponent
        @tag_name = "app:my-component"
      end
      RUBY
      result = RubyUnderstander.get_cmp_name(code, "MyComponent")
      result.should eq "app:my-component"
    end
  end

  describe "get_imports" do
    it "extracts simple require statements with double quotes" do
      code = SpecDataLoader.load("ruby/imports_simple.rb")
      imports = RubyUnderstander.get_imports(code)
      imports.should eq ["json", "file_utils"]
    end

    it "extracts require statements with single quotes" do
      code = SpecDataLoader.load("ruby/imports_single_quotes.rb")
      imports = RubyUnderstander.get_imports(code)
      imports.should eq ["json", "file_utils"]
    end

    it "extracts mixed quote styles" do
      code = SpecDataLoader.load("ruby/imports_mixed.rb")
      imports = RubyUnderstander.get_imports(code)
      imports.should eq ["json", "file_utils", "http/client"]
    end

    it "extracts relative path requires" do
      code = SpecDataLoader.load("ruby/imports_relative.rb")
      imports = RubyUnderstander.get_imports(code)
      imports.should eq ["./lib/helper", "../utils/parser"]
    end

    it "returns empty array when no requires" do
      code = SpecDataLoader.load("ruby/imports_none.rb")
      imports = RubyUnderstander.get_imports(code)
      imports.should eq [] of String
    end

    it "ignores commented out requires" do
      code = SpecDataLoader.load("ruby/imports_with_comments.rb")
      imports = RubyUnderstander.get_imports(code)
      imports.should eq ["json", "file_utils"]
    end

    it "handles indented requires" do
      code = SpecDataLoader.load("ruby/imports_indented.rb")
      imports = RubyUnderstander.get_imports(code)
      imports.should eq ["json", "file_utils"]
    end
  end

  describe "extract_raw_string_from_def_body" do
    it "extracts string from %Q{} format" do
      result = extract_string_from_file("ruby/def_body_uppercase_Q.rb", "html")
      result.should eq "<div>Hello World</div>"
    end

    it "extracts string from %q{} format" do
      result = extract_string_from_file("ruby/def_body_lowercase_q.rb", "text")
      result.should eq "Simple text without interpolation"
    end

    it "extracts string from double quotes" do
      result = extract_string_from_file("ruby/def_body_double_quotes.rb", "title")
      result.should eq "Welcome to My App"
    end

    it "extracts string from single quotes" do
      result = extract_string_from_file("ruby/def_body_single_quotes.rb", "description")
      result.should eq "This is a description"
    end

    it "extracts multiline HTML string" do
      result = extract_string_from_file("ruby/def_body_multiline_html.rb", "html")
      result.should eq "<div class=\"container\">\n    <h1>Title</h1>\n    <p>Content here</p>\n   </div>"
    end

    it "handles tabs in method body" do
      result = extract_string_from_file("ruby/def_body_with_tabs.rb", "template")
      result.should eq "<div>With tabs</div>"
    end

    it "extracts plain return without string delimiters" do
      result = extract_string_from_file("ruby/def_body_plain_return.rb", "value")
      result.should eq "some_method_call"
    end

    it "extracts strings with multi-byte characters without crashing" do
      result = extract_string_from_file("ruby/multi_byte.rb", "html")
      result.should_not be_nil
      result.not_nil!.should contain("Arrows: ←, →")
      
      result_css = extract_string_from_file("ruby/multi_byte.rb", "css")
      result_css.should_not be_nil
      result_css.not_nil!.should contain("content: '│';")
    end
  end

  describe "extract_method_bodies" do
    it "extracts simple method with no parameters" do
      code = SpecDataLoader.load("ruby/methods_simple.rb")
      methods = RubyUnderstander.extract_method_bodies(code, "MyComponent")

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
      methods = RubyUnderstander.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 1
      methods.has_key?("greet").should be_true

      greet_method = methods["greet"]
      greet_method.name.should eq "greet"
      greet_method.parameters.should eq ["name", "age"]
    end

    it "extracts multiple methods" do
      code = SpecDataLoader.load("ruby/methods_multiple.rb")
      methods = RubyUnderstander.extract_method_bodies(code, "MyComponent")

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
      methods = RubyUnderstander.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 1
      check_method = methods["check_value"]
      check_method.parameters.should eq ["value"]
      check_method.body.size.should eq 7
      check_method.body[0].should eq "  def check_value(value)"
      check_method.body[6].should eq "  end"
    end

    it "handles method with loop" do
      code = SpecDataLoader.load("ruby/methods_with_loop.rb")
      methods = RubyUnderstander.extract_method_bodies(code, "MyComponent")

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
      methods = RubyUnderstander.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 1
      empty_method = methods["empty_method"]
      empty_method.parameters.should eq [] of String
      empty_method.body.should eq ["  def empty_method", "  end"]
    end

    it "extracts method with default parameters" do
      code = SpecDataLoader.load("ruby/methods_default_params.rb")
      methods = RubyUnderstander.extract_method_bodies(code, "MyComponent")

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
      methods = RubyUnderstander.extract_method_bodies(code, "MyComponent")

      methods.size.should eq 0
    end

    it "preserves indentation in method body" do
      code = SpecDataLoader.load("ruby/methods_nested_if.rb")
      methods = RubyUnderstander.extract_method_bodies(code, "MyComponent")

      check_method = methods["check_value"]
      check_method.body[1].should eq "    if value > 0"
      check_method.body[2].should eq "      puts \"positive\""
    end
  end

end
