require "./ruby_parser"
require "./bindings"

module TreeSitter
  class StringExtractor

    def self.extract_raw_string_from_def_body(body : Array(String), name : String) : String
      method_source = body.join("\n")

      parser = RubyParser.new
      tree = parser.parse(method_source)
      root = tree.root_node

      method_node = find_method_node(root)
      return extract_from_fallback(body) unless method_node

      return extract_string_from_method_node(method_node) || extract_from_fallback(body)
    end

    def self.extract_string_from_method_node(method_node : Node) : String?
      return nil unless method_node.type == "method"

      body_node = method_node.child_by_field_name("body")
      return nil unless body_node

      string_node = find_string_in_body(body_node)
      return nil unless string_node

      return extract_string_content(string_node)
    end

    private def self.find_method_node(node : Node) : Node?
      return node if node.type == "method"

      node.each_named_child do |child|
        if result = find_method_node(child)
          return result
        end
      end

      nil
    end

    private def self.find_string_in_body(body_node : Node) : Node?
      if body_node.named_child_count == 1
        first_child = body_node.named_child(0)

        case first_child.type
        when "string"
          return first_child

        when "heredoc_body"
          return first_child

        when "array"
          return first_child

        when "return"
          arg_node = first_child.named_child(0)
          if arg_node && (arg_node.type == "string" || arg_node.type.starts_with?("heredoc"))
            return arg_node
          end

        when "call"
          receiver = first_child.child_by_field_name("receiver")
          if receiver && (receiver.type == "string" || receiver.type.starts_with?("heredoc"))
            return receiver
          end
        end
      end

      return find_first_string_node(body_node)
    end

    private def self.find_first_string_node(node : Node) : Node?
      return node if node.type == "string" || node.type.starts_with?("heredoc")

      node.each_named_child do |child|
        if result = find_first_string_node(child)
          return result
        end
      end

      return nil
    end

    private def self.extract_string_content(string_node : Node) : String
      case string_node.type
      when "string"
        return extract_regular_string_content(string_node)
      when "heredoc_body"
        return string_node.text
      when "array"
        return string_node.text
      else
        return string_node.text
      end
    end

    private def self.extract_regular_string_content(string_node : Node) : String
      full_text = string_node.text
      is_percent_string = full_text.starts_with?("%Q{") || full_text.starts_with?("%q{")

      content_parts = [] of String

      string_node.each_child do |child|
        case child.type
        when "string_content"
          content_parts << child.text
        when "interpolation"
          content_parts << child.text
        when "escape_sequence"
          content_parts << child.text
        end
      end

      if content_parts.empty?
        return strip_quote_delimiters(full_text)
      end

      result = content_parts.join

      if is_percent_string
        return normalize_whitespace(result.strip)
      else
        return result
      end
    end

    private def self.normalize_whitespace(text : String) : String
      return text.gsub("  ", " ")
    end

    private def self.strip_quote_delimiters(text : String) : String
      if text.starts_with?("%Q{") && text.ends_with?("}")
        return normalize_whitespace(text[3...-1].strip)
      elsif text.starts_with?("%q{") && text.ends_with?("}")
        return normalize_whitespace(text[3...-1].strip)
      elsif text.starts_with?('"') && text.ends_with?('"')
        return text[1...-1]
      elsif text.starts_with?("'") && text.ends_with?("'")
        return text[1...-1]
      end

      return text
    end

    private def self.extract_from_fallback(body : Array(String)) : String
      return "" if body.size < 2

      inner_body = body[1...body.size - 1]
        .join("\n")
        .strip

      if inner_body.starts_with?("%Q{") && inner_body.ends_with?("}")
        return normalize_whitespace(inner_body[3...-1].strip)
      elsif inner_body.starts_with?("%q{") && inner_body.ends_with?("}")
        return normalize_whitespace(inner_body[3...-1].strip)
      elsif inner_body.starts_with?('"') && inner_body.ends_with?('"')
        return inner_body[1...-1]
      elsif inner_body.starts_with?("'") && inner_body.ends_with?("'")
        return inner_body[1...-1]
      end

      return inner_body
    end

  end
end
