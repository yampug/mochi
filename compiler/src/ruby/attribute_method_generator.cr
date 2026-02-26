require "../html/conditional_processor"
require "./inject_utils"
require "../html/attribute_conditional_extractor"

class AttributeMethodGenerator
  METHOD_PREFIX = "__mochi_attr_cond_"
  END_KEYWORD = "end"
  FALLBACK_OFFSET = 3

  def self.inject_methods_into_class(ruby_code : String, class_name : String, conditionals : Array(ExtractedAttributeConditional)) : String
    return ruby_code if conditionals.empty?

    insertion_point = InjectUtils.find_insertion_point(ruby_code, class_name, END_KEYWORD, FALLBACK_OFFSET)
    return ruby_code unless insertion_point

    methods_code = generate_all_methods(conditionals)
    return InjectUtils.insert_code(ruby_code, insertion_point, methods_code)
  end

  def self.generate_all_methods(conditionals : Array(ExtractedAttributeConditional)) : String
    conditionals.map { |cond|
      generate_method(cond)
    }.join("\n")
  end

  def self.generate_method(cond : ExtractedAttributeConditional) : String
    method_name = "#{METHOD_PREFIX}#{cond.id}"
    attr_string = cond.original_string
    
    blocks = ConditionalProcessor.extract_conditionals(attr_string)
    blocks.sort_by! { |b| b.start_pos }
    
    body = "    _res = \"\"\n"
    
    last_pos = 0
    blocks.each do |block|
      if block.start_pos > last_pos
        text = attr_string[last_pos...block.start_pos]
        body += "    _res += \"#{escape_and_interpolate(text)}\"\n"
      end
      
      body += "    if #{block.condition}\n"
      body += "      _res += \"#{escape_and_interpolate(block.content)}\"\n"
      body += "    end\n"
      
      last_pos = block.end_pos
    end
    
    if last_pos < attr_string.size
      text = attr_string[last_pos..-1]
      body += "    _res += \"#{escape_and_interpolate(text)}\"\n"
    end
    
    body += "    _res\n"

    <<-RUBY

  # auto-generated attribute conditional method
  def #{method_name}
#{body}  end

RUBY
  end

  # Convert `{var}` to `\#{var}` or `\#{@var}` to allow Ruby interpolation
  private def self.escape_and_interpolate(text : String) : String
    # First, escape double quotes so we don't break the generated ruby string literal
    escaped = text.gsub("\"", "\\\"")
    
    # Then replace {var} with \#{var}
    # Note: we need to handle {@var} and {var}
    # If it's already {@var}, it becomes \#{@var}
    escaped.gsub(/\{([^}]+)\}/) do |match, m|
      inner = m[1].strip
      "\#{#{inner}}"
    end
  end
end
