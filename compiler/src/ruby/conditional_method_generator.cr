require "../html/conditional_processor"

class ConditionalMethodGenerator
  METHOD_PREFIX = "__mochi_cond_"
  END_KEYWORD   = "end"
  FALLBACK_OFFSET = 3

  # inject before the class closing 'end'
  def self.inject_methods_into_class(ruby_code : String, class_name : String, conditionals : Array(ConditionalBlock)) : String
    return ruby_code if conditionals.empty?

    insertion_point = find_insertion_point(ruby_code, class_name)
    return ruby_code unless insertion_point

    methods_code = generate_all_methods(conditionals, class_name)
    insert_code(ruby_code, insertion_point, methods_code)
  end

  # generate all conditional methods as a single string
  def self.generate_all_methods(conditionals : Array(ConditionalBlock), class_name : String) : String
    conditionals.map { |block| generate_method(block, class_name) }.join("\n")
  end

  def self.generate_method(block : ConditionalBlock, class_name : String) : String
    method_name = "#{METHOD_PREFIX}#{block.id}"
    condition = block.condition.strip

    <<-RUBY

  # auto-generated conditional method
  def #{method_name}
    #{condition}
  end
RUBY
  end

  private def self.find_insertion_point(ruby_code : String, class_name : String) : Int32?
    second_last_end = find_second_last_end(ruby_code)

    unless second_last_end
      STDERR.puts "Warning: Could not find insertion point for conditional methods in class #{class_name}"
      return nil
    end

    calculate_insertion_point(ruby_code, second_last_end)
  end

  private def self.find_second_last_end(text : String) : Int32?
    last_end = text.rindex(END_KEYWORD)
    return nil unless last_end && last_end > 0

    text.rindex(END_KEYWORD, last_end - 1)
  end

  # calculate exact insertion point (after the line containing the end keyword)
  private def self.calculate_insertion_point(code : String, end_position : Int32) : Int32
    newline_after = code.index("\n", end_position)
    newline_after ? newline_after + 1 : end_position + FALLBACK_OFFSET
  end

  private def self.insert_code(original : String, position : Int32, code_to_insert : String) : String
    original[0...position] + code_to_insert + original[position..-1]
  end
end
