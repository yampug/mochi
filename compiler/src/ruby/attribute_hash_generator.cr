require "./inject_utils"
require "../html/attribute_hash_extractor"

class AttributeHashGenerator
  METHOD_PREFIX = "__mochi_attr_hash_"
  END_KEYWORD = "end"
  FALLBACK_OFFSET = 3

  def self.inject_methods_into_class(ruby_code : String, class_name : String, hashes : Array(ExtractedAttributeHash)) : String
    return ruby_code if hashes.empty?

    insertion_point = InjectUtils.find_insertion_point(ruby_code, class_name, END_KEYWORD, FALLBACK_OFFSET)
    return ruby_code unless insertion_point

    methods_code = generate_all_methods(hashes)
    return InjectUtils.insert_code(ruby_code, insertion_point, methods_code)
  end

  def self.generate_all_methods(hashes : Array(ExtractedAttributeHash)) : String
    hashes.map { |cond|
      generate_method(cond)
    }.join("\n")
  end

  def self.generate_method(cond : ExtractedAttributeHash) : String
    method_name = "#{METHOD_PREFIX}#{cond.id}"
    attr_string = cond.original_string # e.g. {{ "a" => true }}
    
    # Extract the inner part from {{...}}
    inner_hash = attr_string.lchop("{{").rchop("}}").strip
    
    <<-RUBY

  # auto-generated attribute hash method
  def #{method_name}
    _hash = { #{inner_hash} }
    _hash.select { |k, v| v }.keys.join(" ")
  end

RUBY
  end
end
