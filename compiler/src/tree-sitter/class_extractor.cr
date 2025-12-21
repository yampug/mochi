require "./ruby_parser"

module TreeSitter
  class ClassExtractor

    def self.extract_class_names(source : String) : Array(String)
      parser = RubyParser.new
      tree = parser.parse(source)
      root = tree.root_node

      class_names = [] of String
      visit_node(root, class_names)
      class_names
    end

    def self.class_name(source : String) : String
      names = extract_class_names(source)
      names.first? || ""
    end

    private def self.visit_node(node : Node, results : Array(String))
      if node.type == "class"
        if class_name = extract_class_name_from_node(node)
          results << class_name
        end
      end

      # recursively visit the node's children
      node.each_named_child do |child|
        visit_node(child, results)
      end
    end

    # Extract the class name from a class node
    private def self.extract_class_name_from_node(class_node : Node) : String?
      name_node = class_node.child_by_field_name("name")
        return nil unless name_node

      # The name can be either:
      # 1. A simple constant: "MyClass"
      # 2. A scope_resolution: "A::B::MyClass"
      case name_node.type
      when "constant"
        # Simple class name
        name_node.text
      when "scope_resolution"
        # Namespaced class - get the full path
        extract_scope_resolution(name_node)
      else
        # Unexpected node type
        nil
      end
    end

    # Extract full name from scope_resolution node (e.g., "A::B::C")
    private def self.extract_scope_resolution(node : Node) : String
      # Scope resolution has:
      # - scope: the left side (could be another scope_resolution or constant)
      # - name: the right side (constant)

      parts = [] of String

      # Get the left side (scope)
      if scope = node.child_by_field_name("scope")
        case scope.type
        when "constant"
          parts << scope.text
        when "scope_resolution"
          parts << extract_scope_resolution(scope)
        end
      end

      # Get the right side (name)
      if name = node.child_by_field_name("name")
        parts << name.text
      end

      parts.join("::")
    end

    # Extract superclass if present
    def self.extract_superclass(source : String) : String?
      parser = RubyParser.new
      tree = parser.parse(source)
      root = tree.root_node

      class_node = find_first_class(root)
        return nil unless class_node

      superclass_node = class_node.child_by_field_name("superclass")
        return nil unless superclass_node

      # Superclass node contains the parent class name
      superclass_node.text.strip
    end

    private def self.find_first_class(node : Node) : Node?
        return node if node.type == "class"

      node.each_named_child do |child|
        if result = find_first_class(child)
          return result
        end
      end

      nil
    end
  end
end
