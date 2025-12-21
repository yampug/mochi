require "spec"
require "../spec_data_loader"
require "../../src/ruby/ruby_understander"

def check_class_name(exp_name : String, code : String)
  name = RubyUnderstander.class_name(code)
  name.should eq(exp_name)
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

end
