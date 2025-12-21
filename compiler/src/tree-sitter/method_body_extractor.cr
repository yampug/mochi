require "./ruby_parser"
require "./bindings"
require "../ruby/ruby_def"

module TreeSitter
  class MethodBodyExtractor

    def self.extract_method_bodies(source : String, class_name : String) : Hash(String, RubyDef)
      parser = RubyParser.new
      tree = parser.parse(source)
      root = tree.root_node

      methods = {} of String => RubyDef

      class_node = find_class_by_name(root, class_name)
      return methods unless class_node

      visit_node_for_methods(class_node, class_name, methods, source)
      return methods
    end

    private def self.find_class_by_name(node : Node, class_name : String) : Node?
      if node.type == "class"
        if name_node = node.child_by_field_name("name")
          extracted_name = extract_class_name(name_node)
          return node if extracted_name == class_name
        end
      end

      node.each_named_child do |child|
        if result = find_class_by_name(child, class_name)
          return result
        end
      end

      return nil
    end

    private def self.extract_class_name(name_node : Node) : String
      case name_node.type
      when "constant"
        return name_node.text
      when "scope_resolution"
        return extract_scope_resolution(name_node)
      else
        return ""
      end
    end

    private def self.extract_scope_resolution(node : Node) : String
      parts = [] of String

      if scope = node.child_by_field_name("scope")
        case scope.type
        when "constant"
          parts << scope.text
        when "scope_resolution"
          parts << extract_scope_resolution(scope)
        end
      end

      if name = node.child_by_field_name("name")
        parts << name.text
      end

      return parts.join("::")
    end

    private def self.visit_node_for_methods(node : Node, class_name : String, methods : Hash(String, RubyDef), source : String)
      if node.type == "method"
        if ruby_def = extract_method_def(node, class_name, source)
          methods[ruby_def.name.not_nil!] = ruby_def
        end
      end

      node.each_named_child do |child|
        visit_node_for_methods(child, class_name, methods, source)
      end
    end

    private def self.extract_method_def(method_node : Node, class_name : String, source : String) : RubyDef?
      name_node = method_node.child_by_field_name("name")
      return nil unless name_node

      method_name = name_node.text
      parameters = extract_parameters(method_node)
      body = extract_body_as_lines(method_node)

      return RubyDef.new(
        method_name,
        "/todo",
        class_name,
        body,
        parameters
      )
    end

    private def self.extract_parameters(method_node : Node) : Array(String)
      params_node = method_node.child_by_field_name("parameters")
      return [] of String unless params_node

      parameters = [] of String

      params_node.each_named_child do |param|
        case param.type
        when "identifier"
          parameters << param.text
        when "optional_parameter"
          parameters << param.text
        when "splat_parameter"
          parameters << param.text
        when "hash_splat_parameter"
          parameters << param.text
        when "block_parameter"
          parameters << param.text
        when "keyword_parameter"
          parameters << param.text
        else
          parameters << param.text
        end
      end

      return parameters
    end

    private def self.extract_body_as_lines(method_node : Node) : Array(String)
      start_point = LibTreeSitter.ts_node_start_point(method_node.raw)
      end_point = LibTreeSitter.ts_node_end_point(method_node.raw)

      source_lines = method_node.source.lines
      start_row = start_point.row.to_i
      end_row = end_point.row.to_i

      body_lines = [] of String

      (start_row..end_row).each do |row|
        if row < source_lines.size
          body_lines << source_lines[row].chomp
        end
      end

      return body_lines
    end
  end
end
