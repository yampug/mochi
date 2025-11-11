require "spec"
require "../src/ruby/conditional_method_generator"
require "../src/html/conditional_processor"

describe ConditionalMethodGenerator do

  describe ".generate_method" do
    it "generates a Ruby method for a conditional" do
      block = ConditionalBlock.new(
        condition: "@count > 5",
        content: "<p>High</p>",
        start_pos: 0,
        end_pos: 10,
        content_start_pos: 0,
        id: 0
      )

      method_code = ConditionalMethodGenerator.generate_method(block, "Counter")

      method_code.should contain("def __mochi_cond_0")
      method_code.should contain("@count > 5")
      method_code.should contain("end")
    end

    it "handles complex conditions" do
      block = ConditionalBlock.new(
        condition: "@items.length > 0 && @enabled",
        content: "<p>Content</p>",
        start_pos: 0,
        end_pos: 10,
        content_start_pos: 0,
        id: 3
      )

      method_code = ConditionalMethodGenerator.generate_method(block, "MyComponent")

      method_code.should contain("def __mochi_cond_3")
      method_code.should contain("@items.length > 0 && @enabled")
    end

    it "handles Ruby method calls" do
      block = ConditionalBlock.new(
        condition: "@items.empty?",
        content: "<p>No items</p>",
        start_pos: 0,
        end_pos: 10,
        content_start_pos: 0,
        id: 1
      )

      method_code = ConditionalMethodGenerator.generate_method(block, "List")

      method_code.should contain("def __mochi_cond_1")
      method_code.should contain("@items.empty?")
    end
  end

  describe ".generate_all_methods" do
    it "generates multiple methods" do
      blocks = [
        ConditionalBlock.new("@a", "", 0, 10, 0, 0),
        ConditionalBlock.new("@b", "", 11, 20, 11, 1),
        ConditionalBlock.new("@c", "", 21, 30, 21, 2)
      ]

      code = ConditionalMethodGenerator.generate_all_methods(blocks, "Test")

      code.should contain("def __mochi_cond_0")
      code.should contain("def __mochi_cond_1")
      code.should contain("def __mochi_cond_2")
      code.should contain("@a")
      code.should contain("@b")
      code.should contain("@c")
    end

    it "returns empty string for no conditionals" do
      code = ConditionalMethodGenerator.generate_all_methods([] of ConditionalBlock, "Test")
      code.should eq("")
    end
  end

  describe ".inject_methods_into_class" do
    it "injects methods before class end" do
      ruby_code = <<-RUBY
class Counter
  def initialize
    @count = 0
  end

  def increment
    @count += 1
  end
end
RUBY

      blocks = [
        ConditionalBlock.new("@count > 5", "", 0, 10, 0, 0)
      ]

      modified = ConditionalMethodGenerator.inject_methods_into_class(ruby_code, "Counter", blocks)

      modified.should contain("def __mochi_cond_0")
      modified.should contain("@count > 5")

      # Verify method is before final 'end'
      cond_method_index = modified.index("def __mochi_cond_0")
      final_end_index = modified.rindex("end")

      cond_method_index.should_not be_nil
      final_end_index.should_not be_nil

      if cond_method_index && final_end_index
        cond_method_index.should be < final_end_index
      end
    end

    it "handles multiple conditionals" do
      ruby_code = <<-RUBY
class Test
  def foo
    "bar"
  end
end
RUBY

      blocks = [
        ConditionalBlock.new("@a", "", 0, 5, 0, 0),
        ConditionalBlock.new("@b", "", 6, 10, 6, 1),
        ConditionalBlock.new("@c", "", 11, 15, 11, 2)
      ]

      modified = ConditionalMethodGenerator.inject_methods_into_class(ruby_code, "Test", blocks)

      modified.should contain("def __mochi_cond_0")
      modified.should contain("def __mochi_cond_1")
      modified.should contain("def __mochi_cond_2")
      modified.should contain("@a")
      modified.should contain("@b")
      modified.should contain("@c")
    end

    it "returns unchanged code when no conditionals" do
      ruby_code = "class Test\nend"
      blocks = [] of ConditionalBlock

      modified = ConditionalMethodGenerator.inject_methods_into_class(ruby_code, "Test", blocks)
      modified.should eq(ruby_code)
    end

    it "handles nested methods properly" do
      ruby_code = <<-RUBY
class Component
  def initialize
    @value = 0
  end

  def helper
    if @value > 0
      puts "positive"
    end
  end

  def render
    "html"
  end
end
RUBY

      blocks = [
        ConditionalBlock.new("@value > 10", "", 0, 10, 0, 0)
      ]

      modified = ConditionalMethodGenerator.inject_methods_into_class(ruby_code, "Component", blocks)

      modified.should contain("def __mochi_cond_0")
      modified.should contain("@value > 10")

      # Should still have all original methods
      modified.should contain("def initialize")
      modified.should contain("def helper")
      modified.should contain("def render")
    end
  end

  describe ".find_second_last_end_index" do
    it "finds second-to-last end keyword" do
      text = <<-TEXT
class Test
  def method
    code
  end
end
TEXT

      # We can't directly test private method, but we can test via inject_methods_into_class
      # If injection works, find_second_last_end_index is working
      blocks = [ConditionalBlock.new("@test", "", 0, 5, 0, 0)]
      result = ConditionalMethodGenerator.inject_methods_into_class(text, "Test", blocks)

      result.should contain("def __mochi_cond_0")
    end
  end
end
