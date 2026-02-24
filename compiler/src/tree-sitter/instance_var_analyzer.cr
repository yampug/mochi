require "./ruby_parser"

module TreeSitter
  class InstanceVarAnalyzer
    enum Category
      State
      Constant
      Derived
    end

    class VariableInfo
      property name : String
      property writes : Int32 = 0
      property reads : Int32 = 0
      property is_bound : Bool = false
      property attr_mutated : Bool = false
      property initialized_in_constructor : Bool = false
      property written_outside_constructor : Bool = false

      def initialize(@name : String)
      end

      def category : Category
        if attr_mutated || written_outside_constructor
          Category::State
        elsif initialized_in_constructor && !written_outside_constructor
          Category::Constant
        else
          Category::Derived
        end
      end
    end

    def self.analyze(source : String) : Array(VariableInfo)
      parser = RubyParser.new
      tree = parser.parse(source)
      root = tree.root_node

      variables = {} of String => VariableInfo
      
      visit_node(root, variables, nil)
      
      variables.values.to_a
    end

    private def self.get_var(variables, name : String)
      variables[name] ||= VariableInfo.new(name)
    end

    private def self.visit_node(node : Node, variables : Hash(String, VariableInfo), current_method : String?, is_write : Bool = false)
      # Update current method
      if node.type == "method"
        name_node = node.child_by_field_name("name")
        if name_node
          current_method = name_node.text
        end
      end

      # 1. Handle attr_accessor / attr_writer / attr_reader
      method_name = nil
      args_node = nil

      if node.type == "call"
        method_name_node = node.child_by_field_name("method")
        method_name = method_name_node ? method_name_node.text : nil
        args_node = node.child_by_field_name("arguments")
      elsif node.type == "command"
        method_name_node = node.child_by_field_name("name")
        method_name = method_name_node ? method_name_node.text : nil
        args_node = node.child_by_field_name("arguments")
      end

      if method_name && method_name.in?("attr_accessor", "attr_writer", "attr_reader")
          if args_node
            args_node.each_named_child do |arg|
              if arg.type == "simple_symbol"
                # Strip the leading ':' and prefix with '@'
                var_name = "@#{arg.text.lchop(":")}"
                var_info = get_var(variables, var_name)
                if method_name == "attr_accessor" || method_name == "attr_writer"
                  var_info.attr_mutated = true
                end
                if method_name == "attr_accessor" || method_name == "attr_reader"
                  # Assuming it's readable
                  var_info.reads += 1
                end
              end
            end
          end
      end

      # 2. Handle assignments and reads for instance_variables
      if node.type.in?("assignment", "operator_assignment")
        left_node = node.child_by_field_name("left")
        right_node = node.child_by_field_name("right")
        
        if left_node
          visit_node(left_node, variables, current_method, true)
        end
        if right_node
          visit_node(right_node, variables, current_method, false)
        end
        return # prevent double traversal
      end

      if node.type == "instance_variable"
        var_name = node.text
        var_info = get_var(variables, var_name)
        
        if current_method == "html"
          var_info.is_bound = true
        end

        if is_write
          var_info.writes += 1
          if current_method == "initialize"
            var_info.initialized_in_constructor = true
          else
            var_info.written_outside_constructor = true
          end
        else
          var_info.reads += 1
        end
      end

      # 3. Handle string_content for interpolations inside html
      if current_method == "html" && node.type == "string_content"
        content = node.text
        
        # Scan for anything inside braces
        content.scan(/\{([^}]+)\}/) do |match|
          inner = match[1].strip
          
          # Skip control flow
          next if inner.starts_with?("if ") || inner.starts_with?("each ") || inner.starts_with?("elsif ") || inner.starts_with?("unless ") || inner == "else" || inner == "end"

          # Handle explicit instance var: {@var}
          if inner =~ /^@[a-zA-Z0-9_]+$/
             var_name = inner
             var_info = get_var(variables, var_name)
             var_info.is_bound = true
             var_info.reads += 1
             next
          end

          # Handle implicit var: {var}
          if inner =~ /^[a-zA-Z0-9_]+$/
             name = inner
             # implicit binding
             keywords = ["if", "else", "elsif", "end", "unless", "while", "until", "case", "when", "then", "do", "begin", "rescue", "true", "false", "nil", "self", "super"]
             unless keywords.includes?(name)
                var_name = "@#{name}"
                var_info = get_var(variables, var_name)
                var_info.is_bound = true
                var_info.reads += 1
             end
          end
        end
      end
      
      # Standard ruby #{} interpolation nodes contain `interpolation` nodes, which we traverse into normally.
      
      # Traverse children
      node.each_named_child do |child|
        visit_node(child, variables, current_method, false)
      end
    end
  end
end
