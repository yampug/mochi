require "../html/conditional_processor"
require "./inject_utils"

class ConditionalMethodGenerator
  METHOD_PREFIX = "__mochi_cond_"
  END_KEYWORD = "end"
  FALLBACK_OFFSET = 3

  # inject before the class closing 'end'
  def self.inject_methods_into_class(ruby_code : String, class_name : String, conditionals : Array(ConditionalBlock)) : String
    return ruby_code if conditionals.empty?

    insertion_point = InjectUtils.find_insertion_point(ruby_code, class_name, END_KEYWORD, FALLBACK_OFFSET)
    return ruby_code unless insertion_point

    methods_code = generate_all_methods(conditionals, class_name)
    return InjectUtils.insert_code(ruby_code, insertion_point, methods_code)
  end

  # generate all conditional methods as a single string
  def self.generate_all_methods(conditionals : Array(ConditionalBlock), class_name : String) : String
    conditionals.map { |block|
      generate_method(block, class_name)
    }.join("\n")
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

end
