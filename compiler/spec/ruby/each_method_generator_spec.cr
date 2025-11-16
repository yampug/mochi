require "spec"
require "../spec_data_loader"
require "../../src/ruby/each_method_generator"
require "../../src/ruby/conditional_method_generator"

describe EachMethodGenerator do
  it "generate_method - no index" do
    exp_code = SpecDataLoader.load("ruby/each_generated_method_a.rb")
    loop_def : EachLoopDef = EachProcessor.extract_loop_definition("@items as item").not_nil!
    block = EachBlock.new(
      loop_def,
      "<li>{item.name}</li>",
      0,
      56,
      31,
      123
    )
    ruby_code = EachMethodGenerator.generate_method(block, "abc")
    ruby_code.should eq(exp_code)
  end

  it "generate_method - with index" do
    exp_code = SpecDataLoader.load("ruby/each_method_array_entry_k.rb")
    loop_def : EachLoopDef = EachProcessor.extract_loop_definition("@array as entry, k").not_nil!
    block = EachBlock.new(
      loop_def,
      "<li>{entry.name}</li>",
      0,
      56,
      31,
      123
    )
    ruby_code = EachMethodGenerator.generate_method(block, "abc")
    ruby_code.should eq(exp_code)
  end

  it "inject: no each blocks" do
    each_blocks = [] of EachBlock
    result = EachMethodGenerator.inject_methods_into_class("", "", each_blocks)
    result.should eq("")
  end

  describe ".generate_method" do
    it "generates correct method names based on block id" do
      loop_def = EachLoopDef.new("@items", "item", nil)
      block = EachBlock.new(loop_def, "<p>{item.text}</p>", 0, 20, 10, 42)

      ruby_code = EachMethodGenerator.generate_method(block, "Test")

      ruby_code.should contain("def __mochi_each_42_items")
      ruby_code.should contain("def __mochi_each_42_key")
    end

    it "generates methods that return array and key" do
      loop_def = EachLoopDef.new("@users", "user", "i")
      block = EachBlock.new(loop_def, "<div>{user.name}</div>", 0, 30, 15, 1)

      ruby_code = EachMethodGenerator.generate_method(block, "UserList")

      ruby_code.should contain("return @users")
      ruby_code.should contain("return user.id")
    end

    it "includes auto-generated comment" do
      loop_def = EachLoopDef.new("@items", "item", nil)
      block = EachBlock.new(loop_def, "<p>content</p>", 0, 20, 10, 0)

      ruby_code = EachMethodGenerator.generate_method(block, "Test")

      ruby_code.should contain("# auto-generated each method")
    end

    it "handles different array names" do
      loop_def = EachLoopDef.new("@products", "prod", nil)
      block = EachBlock.new(loop_def, "<li>{prod.title}</li>", 0, 25, 12, 5)

      ruby_code = EachMethodGenerator.generate_method(block, "ProductList")

      ruby_code.should contain("return @products")
    end
  end

  describe ".generate_all_methods" do
    it "generates multiple methods for multiple blocks" do
      blocks = [
        EachBlock.new(
          EachLoopDef.new("@items", "item", nil),
          "<p>{item.name}</p>",
          0, 20, 10, 0
        ),
        EachBlock.new(
          EachLoopDef.new("@users", "user", "i"),
          "<div>{user.email}</div>",
          30, 60, 40, 1
        ),
        EachBlock.new(
          EachLoopDef.new("@products", "prod", nil),
          "<li>{prod.title}</li>",
          70, 100, 80, 2
        )
      ]

      code = EachMethodGenerator.generate_all_methods(blocks, "TestComponent")

      code.should contain("def __mochi_each_0_items")
      code.should contain("def __mochi_each_0_key")
      code.should contain("def __mochi_each_1_items")
      code.should contain("def __mochi_each_1_key")
      code.should contain("def __mochi_each_2_items")
      code.should contain("def __mochi_each_2_key")
      code.should contain("return @items")
      code.should contain("return @users")
      code.should contain("return @products")
    end

    it "returns empty string for no each blocks" do
      code = EachMethodGenerator.generate_all_methods([] of EachBlock, "Test")
      code.should eq("")
    end

    it "handles single each block" do
      blocks = [
        EachBlock.new(
          EachLoopDef.new("@data", "d", nil),
          "<span>{d.value}</span>",
          0, 25, 12, 99
        )
      ]

      code = EachMethodGenerator.generate_all_methods(blocks, "Single")

      code.should contain("def __mochi_each_99_items")
      code.should contain("def __mochi_each_99_key")
      code.should contain("return @data")
    end
  end

  describe ".inject_methods_into_class" do
    it "injects methods before class end" do
      ruby_code = SpecDataLoader.load("ruby/simple_component.rb")

      blocks = [
        EachBlock.new(
          EachLoopDef.new("@items", "item", nil),
          "<p>{item.name}</p>",
          0, 20, 10, 0
        )
      ]

      modified = EachMethodGenerator.inject_methods_into_class(ruby_code, "SimpleComponent", blocks)

      modified.should contain("def __mochi_each_0_items")
      modified.should contain("def __mochi_each_0_key")
      modified.should contain("return @items")

      # verify methods are before final 'end'
      items_method_index = modified.index("def __mochi_each_0_items")
      final_end_index = modified.rindex("end")

      items_method_index.should_not be_nil
      final_end_index.should_not be_nil

      if items_method_index && final_end_index
        items_method_index.should be < final_end_index
      end
    end

    it "handles multiple each blocks" do
      ruby_code = SpecDataLoader.load("ruby/simple_component.rb")

      blocks = [
        EachBlock.new(
          EachLoopDef.new("@items", "item", nil),
          "<p>{item.name}</p>",
          0, 20, 10, 0
        ),
        EachBlock.new(
          EachLoopDef.new("@users", "user", "idx"),
          "<div>{user.email}</div>",
          30, 60, 40, 1
        )
      ]

      modified = EachMethodGenerator.inject_methods_into_class(ruby_code, "SimpleComponent", blocks)

      modified.should contain("def __mochi_each_0_items")
      modified.should contain("def __mochi_each_0_key")
      modified.should contain("def __mochi_each_1_items")
      modified.should contain("def __mochi_each_1_key")
    end

    it "handles complex classes with nested methods" do
      ruby_code = SpecDataLoader.load("ruby/complex_component.rb")

      blocks = [
        EachBlock.new(
          EachLoopDef.new("@items", "item", "i"),
          "<li>{item.title} - {i}</li>",
          0, 30, 15, 0
        )
      ]

      modified = EachMethodGenerator.inject_methods_into_class(ruby_code, "ComplexComponent", blocks)

      modified.should contain("def __mochi_each_0_items")
      modified.should contain("def __mochi_each_0_key")

      # should still have all original methods
      modified.should contain("def initialize")
      modified.should contain("def add_item")
      modified.should contain("def helper_method")
      modified.should contain("def render")
    end

    it "preserves existing code structure" do
      ruby_code = <<-RUBY
class ItemList
  def initialize
    @items = []
  end

  def count
    @items.size
  end
end
RUBY

      blocks = [
        EachBlock.new(
          EachLoopDef.new("@items", "item", nil),
          "<p>{item.text}</p>",
          0, 20, 10, 3
        )
      ]

      modified = EachMethodGenerator.inject_methods_into_class(ruby_code, "ItemList", blocks)

      # original methods should still be present
      modified.should contain("def initialize")
      modified.should contain("def count")
      modified.should contain("@items = []")
      modified.should contain("@items.size")

      # new methods should be added
      modified.should contain("def __mochi_each_3_items")
      modified.should contain("def __mochi_each_3_key")
    end

    it "handles empty ruby code gracefully" do
      ruby_code = ""
      blocks = [
        EachBlock.new(
          EachLoopDef.new("@items", "item", nil),
          "<p>test</p>",
          0, 10, 5, 0
        )
      ]

      modified = EachMethodGenerator.inject_methods_into_class(ruby_code, "Test", blocks)
      # should return unchanged when no insertion point found
      # Note: The warning "Could not find insertion point for methods in class Test" is expected behavior from the
      # test that validates graceful handling of empty Ruby code.
      modified.should eq(ruby_code)
    end

    it "works together with conditional method injection" do
      ruby_code = <<-RUBY
class MixedComponent
  def initialize
    @items = []
    @show_list = false
  end

  def add_item(item)
    @items << item
  end
end
RUBY

      each_blocks = [
        EachBlock.new(
          EachLoopDef.new("@items", "item", "idx"),
          "<li>{item.name} - {idx}</li>",
          0, 30, 15, 0
        ),
        EachBlock.new(
          EachLoopDef.new("@users", "user", nil),
          "<div>{user.email}</div>",
          50, 80, 60, 1
        )
      ]

      conditional_blocks = [
        ConditionalBlock.new("@show_list", "", 0, 10, 0, 0),
        ConditionalBlock.new("@items.length > 0", "", 20, 30, 20, 1)
      ]

      # First inject conditionals
      modified = ConditionalMethodGenerator.inject_methods_into_class(ruby_code, "MixedComponent", conditional_blocks)

      # Then inject each methods
      modified = EachMethodGenerator.inject_methods_into_class(modified, "MixedComponent", each_blocks)

      # Verify all conditional methods are present
      modified.should contain("def __mochi_cond_0")
      modified.should contain("@show_list")
      modified.should contain("def __mochi_cond_1")
      modified.should contain("@items.length > 0")

      # Verify all each methods are present
      modified.should contain("def __mochi_each_0_items")
      modified.should contain("def __mochi_each_0_key(item, idx)")
      modified.should contain("return @items")
      modified.should contain("def __mochi_each_1_items")
      modified.should contain("def __mochi_each_1_key(user, index)")
      modified.should contain("return @users")

      # Verify original methods are preserved
      modified.should contain("def initialize")
      modified.should contain("def add_item")

      # Verify all methods are before final 'end'
      final_end_index = modified.rindex("end")
      final_end_index.should_not be_nil

      if final_end_index
        cond_0_index = modified.index("def __mochi_cond_0")
        each_0_index = modified.index("def __mochi_each_0_items")

        cond_0_index.should_not be_nil
        each_0_index.should_not be_nil

        if cond_0_index && each_0_index
          cond_0_index.should be < final_end_index
          each_0_index.should be < final_end_index
        end
      end
    end
  end
end
