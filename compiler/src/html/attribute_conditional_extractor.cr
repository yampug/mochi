class ExtractedAttributeConditional
  property id : Int32
  property original_string : String
  property attribute_name : String

  def initialize(@id : Int32, @original_string : String, @attribute_name : String)
  end
end

class AttributeConditionalResult
  property html : String
  property conditionals : Array(ExtractedAttributeConditional)

  def initialize(@html : String, @conditionals : Array(ExtractedAttributeConditional))
  end
end

class AttributeConditionalExtractor
  def self.process(html : String) : AttributeConditionalResult
    conditionals = [] of ExtractedAttributeConditional
    next_id = 0
    
    # Regex finds attributes whose values contain `{if ` or `{unless `
    # Group 1: attribute name
    # Group 2: quote character (" or ')
    # Group 3: attribute value
    regex = /([a-zA-Z0-9_\-\:]+)\s*=\s*(["'])((?:(?!\2).)*(?:\{if |\{unless )(?:(?!\2).)*)\2/m
    
    processed_html = html.gsub(regex) do |match, m|
      attr_name = m[1]
      quote = m[2]
      attr_value = m[3]
      
      cond = ExtractedAttributeConditional.new(next_id, attr_value, attr_name)
      conditionals << cond
      
      replacement_value = "{__mochi_attr_cond_#{next_id}}"
      next_id += 1
      
      "#{attr_name}=#{quote}#{replacement_value}#{quote}"
    end

    AttributeConditionalResult.new(processed_html, conditionals)
  end
end
