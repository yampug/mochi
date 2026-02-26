class ExtractedAttributeHash
  property id : Int32
  property original_string : String
  property attribute_name : String

  def initialize(@id : Int32, @original_string : String, @attribute_name : String)
  end
end

class AttributeHashResult
  property html : String
  property hashes : Array(ExtractedAttributeHash)

  def initialize(@html : String, @hashes : Array(ExtractedAttributeHash))
  end
end

class AttributeHashExtractor
  def self.process(html : String) : AttributeHashResult
    hashes = [] of ExtractedAttributeHash
    next_id = 0
    
    # Needs to match: attribute={{...}} OR attribute="{{...}}"
    regex = /([a-zA-Z0-9_\-\:]+)\s*=\s*(?:(["'])(\{\{.*?\}\})\2|\{\{(.*?)\}\})/m
    
    processed_html = html.gsub(regex) do |match, m|
      attr_name = m[1]
      
      # Either they wrapped in quotes, or not
      attr_value = m[3]? ? m[3] : "{{#{m[4]?}}}"
      
      cond = ExtractedAttributeHash.new(next_id, attr_value, attr_name)
      hashes << cond
      
      replacement_value = "{__mochi_attr_hash_#{next_id}}"
      next_id += 1
      
      "#{attr_name}=\"#{replacement_value}\""
    end

    AttributeHashResult.new(processed_html, hashes)
  end
end
