require "spec"
require "json"
require "../../src/ruby/ruby_endable_statement"
require "../../src/ruby/ruby_def"
require "../../src/bind_extractor"
require "../../src/html/conditional_processor"
require "../../src/ruby/conditional_method_generator"
require "../../src/ruby/ruby_understander"
require "../../src/webcomponents/web_component_generator"
require "../../src/webcomponents/web_component"
require "../../src/mochi_cmp"

def find_second_last_index(text : String, substring_to_find : String) : Int32?
  last_idx = text.rindex(substring_to_find)
  unless last_idx && last_idx > 0
    return -1
  end
  second_last_idx = text.rindex(substring_to_find, last_idx - 1)
  return second_last_idx
end

def js_to_cr_array(json_array_str : String) : Array(String)
  parsed_array = JSON.parse(json_array_str).as_a
  string_array = parsed_array.map(&.as_s)
  return string_array
end

def transpile_test_component(rb_file : String)
  cls_name = RubyUnderstander.class_name(rb_file)
  return nil if cls_name.blank?

  methods = RubyUnderstander.extract_method_bodies(rb_file, cls_name)
  amped_ruby_code = rb_file

  if methods.has_key?("css")
    imports = RubyUnderstander.get_imports(rb_file)
    css = RubyUnderstander.extract_raw_string_from_def_body(methods["css"].body, "css")
    html = RubyUnderstander.extract_raw_string_from_def_body(methods["html"].body, "html")
    reactables = RubyUnderstander.extract_raw_string_from_def_body(methods["reactables"].body, "reactables")

    reactables_arr = js_to_cr_array(reactables)

    # Process conditionals
    conditional_result = ConditionalProcessor.process(html)

    # Inject conditional methods
    amped_ruby_code = ConditionalMethodGenerator.inject_methods_into_class(
      amped_ruby_code,
      cls_name,
      conditional_result.conditionals
    )

    bindings = BindExtractor.extract(conditional_result.html)
    tag_name = RubyUnderstander.get_cmp_name(rb_file, cls_name)

    if tag_name
      # Add getters & setters
      reactables_arr.each do |reactable|
        var_name = reactable
        second_last_index = find_second_last_index(amped_ruby_code, "end")

        if second_last_index
          insertion_point = second_last_index + 3
          getter_code_to_insert = "\n\n\tdef get_#{var_name}\n\t\t@#{var_name}\n\tend\n"
          amped_ruby_code = amped_ruby_code[0...insertion_point] + getter_code_to_insert + amped_ruby_code[insertion_point..-1]

          setter_code_to_insert = "\n\n\tdef set_#{var_name}(value)\n\t\t@#{var_name} = value\n\tend\n"
          amped_ruby_code = amped_ruby_code[0...insertion_point] + setter_code_to_insert + amped_ruby_code[insertion_point..-1]
        end
      end

      web_comp_generator = WebComponentGenerator.new
      web_component = web_comp_generator.generate(
        mochi_cmp_name = cls_name,
        tag_name = tag_name.not_nil!,
        css,
        html = bindings.html.not_nil!,
        reactables,
        bindings.bindings,
        conditional_result.conditionals
      )

      return MochiComponent.new(
        "/test/component.rb",
        cls_name,
        imports,
        ruby_code = amped_ruby_code,
        web_component,
        html,
        css
      )
    end
  end

  return nil
end

describe "Conditional Integration" do
  describe "end-to-end transpilation" do
    it "generates conditional methods and calls them from JavaScript" do
      component_code = <<-RUBY
class TestComponent
  @tag_name = "test-comp"
  @count
  @enabled

  def initialize
    @count = 0
    @enabled = true
  end

  def reactables
    ["count", "enabled"]
  end

  def html
    %Q{
      <div>
        <h1>Count: {count}</h1>
        {if @count > 5}
          <p>High count!</p>
        {end}
        {if @enabled}
          <p>Enabled</p>
        {end}
        {if @count < 0}
          <p>Negative!</p>
        {end}
      </div>
    }
  end

  def css
    %Q{
      .wrapper { color: red; }
    }
  end

  def increment
    @count += 1
  end
end
RUBY

      component = transpile_test_component(component_code)
      component.should_not be_nil

      if component
        ruby_code = component.ruby_code
        js_code = component.web_component.js_code

        # Verify Ruby methods were generated
        ruby_code.should contain("def __mochi_cond_0")
        ruby_code.should contain("def __mochi_cond_1")
        ruby_code.should contain("def __mochi_cond_2")

        # Verify conditions are in method bodies
        ruby_code.should contain("@count > 5")
        ruby_code.should contain("@enabled")
        ruby_code.should contain("@count < 0")

        # Verify JavaScript calls methods by ID
        js_code.should contain("evaluateCondition(condId)")
        js_code.should contain("$__mochi_cond_")

        # Verify data-cond-id is used
        js_code.should contain("data-cond-id")

        # Verify old approach is removed
        js_code.should_not contain("condition.replace(/@")

        # Verify original methods still present
        ruby_code.should contain("def increment")
        ruby_code.should contain("def get_count")
        ruby_code.should contain("def set_count")
      end
    end

    it "handles components without conditionals" do
      component_code = <<-RUBY
class SimpleComponent
  @tag_name = "simple-comp"
  @value

  def initialize
    @value = 0
  end

  def reactables
    ["value"]
  end

  def html
    %Q{
      <div>
        <p>Value: {value}</p>
      </div>
    }
  end

  def css
    %Q{
      p { color: blue; }
    }
  end
end
RUBY

      component = transpile_test_component(component_code)
      component.should_not be_nil

      if component
        ruby_code = component.ruby_code

        # Should not have conditional methods
        ruby_code.should_not contain("__mochi_cond_")

        # Should still have getters/setters
        ruby_code.should contain("def get_value")
        ruby_code.should contain("def set_value")
      end
    end

    it "handles nested conditionals correctly" do
      component_code = <<-RUBY
class NestedComponent
  @tag_name = "nested-comp"
  @outer
  @inner

  def initialize
    @outer = true
    @inner = false
  end

  def reactables
    ["outer", "inner"]
  end

  def html
    %Q{
      <div>
        {if @outer}
          <div>
            <p>Outer</p>
            {if @inner}
              <p>Inner</p>
            {end}
          </div>
        {end}
      </div>
    }
  end

  def css
    %Q{
      div { padding: 10px; }
    }
  end
end
RUBY

      component = transpile_test_component(component_code)
      component.should_not be_nil

      if component
        ruby_code = component.ruby_code
        js_code = component.web_component.js_code

        # Should have methods for both conditionals
        ruby_code.should contain("def __mochi_cond_0")
        ruby_code.should contain("def __mochi_cond_1")

        # Both conditions should be present
        ruby_code.should contain("@outer")
        ruby_code.should contain("@inner")

        # HTML should have both data-cond-id attributes
        js_code.should contain("data-cond-id=\"0\"")
        js_code.should contain("data-cond-id=\"1\"")
      end
    end

    it "handles complex Ruby expressions" do
      component_code = <<-RUBY
class ComplexComponent
  @tag_name = "complex-comp"
  @items
  @user

  def initialize
    @items = []
    @user = nil
  end

  def reactables
    ["items", "user"]
  end

  def html
    %Q{
      <div>
        {if @items.empty?}
          <p>No items</p>
        {end}
        {if @user.nil?}
          <p>No user</p>
        {end}
        {if @items.length > 10 && !@user.nil?}
          <p>Many items and user present</p>
        {end}
      </div>
    }
  end

  def css
    %Q{
      div { margin: 5px; }
    }
  end
end
RUBY

      component = transpile_test_component(component_code)
      component.should_not be_nil

      if component
        ruby_code = component.ruby_code

        # Should have three conditional methods
        ruby_code.should contain("def __mochi_cond_0")
        ruby_code.should contain("def __mochi_cond_1")
        ruby_code.should contain("def __mochi_cond_2")

        # Complex Ruby expressions should be preserved exactly
        ruby_code.should contain("@items.empty?")
        ruby_code.should contain("@user.nil?")
        ruby_code.should contain("@items.length > 10 && !@user.nil?")
      end
    end
  end
end
