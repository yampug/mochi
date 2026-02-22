require "lexbor"

module TreeSitter

  struct PathBinding
    property path : Array(Int32)
    property type : String # "text" or "attribute"
    property attr_name : String?
    property expression : String # e.g. "@count" or "{@count}"

    def initialize(@path : Array(Int32), @type : String, @expression : String, @attr_name : String? = nil)
    end
  end

  class HTMLBindingExtractor
    struct Result
      property html : String
      property bindings : Array(PathBinding)

      def initialize(@html : String, @bindings : Array(PathBinding))
      end
    end

    def self.extract(html : String) : Result
      doc = Lexbor.new(html)
      body = doc.nodes(:body).first

      bindings = [] of PathBinding

      # walk the tree starting from bodys children
      body.children.each_with_index do |child, idx|
        walk(child, [idx], bindings)
      end

      # extract the HTML inside the body but we need to re-serialize
      cleaned_html = doc.to_html
      body_open_tag = "<body>"
      body_close_tag = "</body>"
      body_open_index = cleaned_html.index(body_open_tag)
      body_end_index = cleaned_html.index(body_close_tag)

      final_html = html
      if body_open_index && body_end_index && body_open_index < body_end_index
        final_html = cleaned_html[(body_open_index + body_open_tag.size)...body_end_index]
      end

      Result.new(final_html, bindings)
    end

    private def self.walk(node, current_path, bindings)
      if node.textable?
        text = node.tag_text
        if text.includes?("{") && text.includes?("}")
          # Extract all interpolations (could be multiple, but we assume the whole text node is replaced or we just record it)
          # "For every Text Node containing {...} Replace content with placeholder (empty string)"

          # We just extract the first binding for simplicity, or the whole text?
          # "record the path"
          # "replace content with placeholder (empty string or space)"
          node.tag_text_set(" ")

          # Use the raw expression or extract what's inside {}?
          # store the full text as expression
          # or extract the inner content? "extract dynamic bindings({...})"
          bindings << PathBinding.new(current_path, "text", text.strip)
        end
      else
        # Inspect attributes
        # node.attributes is a Hash(String, String) if its set
        attrs_to_remove = [] of String

        node.attributes.each do |key, val|
          if val.includes?("{") && val.includes?("}")
            bindings << PathBinding.new(current_path, "attribute", val.strip, key)
            attrs_to_remove << key
          end
        end

        attrs_to_remove.each do |k|
          node.attribute_remove(k)
        end
      end

      node.children.each_with_index do |child, idx|
        walk(child, current_path + [idx], bindings)
      end
    end
  end
end
