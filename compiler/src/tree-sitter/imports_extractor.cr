require "./ruby_parser"

module TreeSitter
  class ImportsExtractor
    def self.extract_imports(source : String) : Array(String)
      parser = RubyParser.new
      tree = parser.parse(source)
      root = tree.root_node

      imports = [] of String
      visit_node(root, imports)
      imports
    end

    private def self.visit_node(node : Node, results : Array(String))
      if node.type == "call"
        if import = extract_import_from_call(node)
          results << import
        end
      end

      node.each_named_child do |child|
        visit_node(child, results)
      end
    end

    private def self.extract_import_from_call(call_node : Node) : String?
      method_node = call_node.child_by_field_name("method")
      return nil unless method_node

      return nil unless method_node.text == "require"

      arguments_node = call_node.child_by_field_name("arguments")
      return nil unless arguments_node

      arguments_node.each_named_child do |arg|
        if arg.type == "string"
          return extract_string_content(arg)
        end
      end

      nil
    end

    private def self.extract_string_content(string_node : Node) : String
      string_node.each_named_child do |child|
        if child.type == "string_content"
          return child.text
        end
      end

      text = string_node.text

      if text.starts_with?("\"") && text.ends_with?("\"")
        return text[1...-1]
      end

      if text.starts_with?("'") && text.ends_with?("'")
        return text[1...-1]
      end

      text
    end
  end
end
