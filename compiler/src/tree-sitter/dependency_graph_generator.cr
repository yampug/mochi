require "./instance_var_analyzer"
require "../html/html_binding_extractor"

module TreeSitter
  struct DomOperation
    property path : Array(Int32)
    property type : String # "text" or "attribute"
    property attr_name : String?

    def initialize(@path : Array(Int32), @type : String, @attr_name : String? = nil)
    end
  end

  class DependencyGraphGenerator
    struct Result
      property dependencies : Hash(String, Array(DomOperation))

      def initialize(@dependencies : Hash(String, Array(DomOperation)))
      end
    end

    def self.generate(source : String) : Result
      # 1. Analyze instance variables to find bound state
      vars = InstanceVarAnalyzer.analyze(source)
      bound_vars = vars.select(&.is_bound)

      # 2. Extract HTML bindings
      # we need a quick parsing to find def html
      parser = RubyParser.new
      tree = parser.parse(source)
      html_string = extract_html_method_string(tree.root_node)

      deps = Hash(String, Array(DomOperation)).new { |h, k| h[k] = [] of DomOperation }

      if html_string
        html_result = HTMLBindingExtractor.extract(html_string)

        # 3. Map expression back to variable
        html_result.bindings.each do |binding|
          # The binding expression is usually something like "{@count}"
          # We need to extract the var name "@count"
          var_matches = binding.expression.scan(/\{@([a-zA-Z0-9_]+)\}/)
          var_matches.each do |match|
            var_name = "@#{match[1]}"
            # check if its a known bound variable
            if bound_vars.any? { |v| v.name == var_name }
              deps[var_name] << DomOperation.new(binding.path, binding.type, binding.attr_name)
            end
          end

          # Implicit binding {count} -> @count
          implicit_matches = binding.expression.scan(/\{([a-zA-Z0-9_]+)\}/)
          keywords = ["if", "else", "elsif", "end", "unless", "while", "until", "case", "when", "then", "do", "begin", "rescue", "true", "false", "nil", "self", "super"]
          implicit_matches.each do |match|
            name = match[1]
            unless keywords.includes?(name)
              var_name = "@#{name}"
              if bound_vars.any? { |v| v.name == var_name }
                deps[var_name] << DomOperation.new(binding.path, binding.type, binding.attr_name)
              end
            end
          end
        end
      end

      Result.new(deps)
    end

    private def self.extract_html_method_string(node : Node) : String?
      if node.type == "method"
        name_node = node.child_by_field_name("name")
        if name_node && name_node.text == "html"
          # Find the string returned
          return find_string_content(node)
        end
      end

      node.each_named_child do |child|
        if result = extract_html_method_string(child)
          return result
        end
      end

      nil
    end

    private def self.find_string_content(node : Node) : String?
      if node.type == "string"
        content = ""
        node.each_child do |child|
          case child.type
          when "string_content", "escape_sequence"
            content += child.text
          when "interpolation"
            content += "\#{#{child.text[2...-1]}}"
          end
        end
        return content unless content.empty?

        text = node.text
        if text.starts_with?('"') || text.starts_with?("'")
          return text[1...-1]
        end
        return text
      end

      node.each_named_child do |child|
        if result = find_string_content(child)
          return result
        end
      end

      nil
    end
  end
end
