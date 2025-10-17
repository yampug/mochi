require "../html/conditional_processor"

class ConditionalMethodGenerator

  # Generate Ruby method code for a single conditional
  def self.generate_method(block : ConditionalBlock, class_name : String) : String
    method_name = "__mochi_cond_#{block.id}"

    # Clean up condition for Ruby method body
    condition = block.condition.strip

    # Generate method with proper indentation
    <<-RUBY

  # Auto-generated conditional method
  def #{method_name}
    #{condition}
  end
RUBY
  end

  # Generate all conditional methods for a component
  def self.generate_all_methods(conditionals : Array(ConditionalBlock), class_name : String) : String
    return "" if conditionals.empty?

    methods_code = ""
    conditionals.each do |block|
      methods_code += generate_method(block, class_name)
      methods_code += "\n"
    end

    methods_code
  end

  # Inject conditional methods into Ruby class code
  def self.inject_methods_into_class(ruby_code : String, class_name : String, conditionals : Array(ConditionalBlock)) : String
    return ruby_code if conditionals.empty?

    # Find the last 'end' in the class (class closing)
    second_last_end_index = find_second_last_end_index(ruby_code)

    if second_last_end_index.nil? || second_last_end_index < 0
      STDERR.puts "Warning: Could not find insertion point for conditional methods in class #{class_name}"
      return ruby_code
    end

    # Generate all methods
    methods_code = generate_all_methods(conditionals, class_name)

    # Find the end of the line containing the second-to-last 'end'
    # We want to inject AFTER this line, not before the keyword
    newline_after = ruby_code.index("\n", second_last_end_index)
    insertion_point = newline_after ? newline_after + 1 : second_last_end_index + 3

    modified_code = ruby_code[0...insertion_point] + methods_code + ruby_code[insertion_point..-1]

    modified_code
  end

  # Helper to find second-to-last 'end' keyword
  private def self.find_second_last_end_index(text : String) : Int32?
    last_idx = text.rindex("end")

    unless last_idx && last_idx > 0
      return nil
    end

    # Find second-to-last 'end'
    second_last_idx = text.rindex("end", last_idx - 1)
    return second_last_idx
  end
end
