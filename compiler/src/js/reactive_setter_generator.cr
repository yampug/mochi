require "../tree-sitter/dependency_graph_generator"

module JS
  class ReactiveSetterGenerator
    def self.generate(var_name : String, operations : Array(TreeSitter::DomOperation)) : String
      clean_name = var_name.lchop('@')
      
      String.build do |io|
        io << "  get #{clean_name}() { return this._#{clean_name}; }\n"
        io << "  set #{clean_name}(val) {\n"
        io << "    if (val === this._#{clean_name}) return;\n"
        io << "    this._#{clean_name} = val;\n"
        
        operations.each do |op|
          dom_ref = "this._dom_#{op.path.join('_')}"
          if op.type == "text"
            io << "    #{dom_ref}.data = val;\n"
          elsif op.type == "attribute"
            # Fallback defensively if attr_name is nil despite type being attribute
            if attr_name = op.attr_name
              io << "    #{dom_ref}.setAttribute(#{attr_name.inspect}, val);\n"
            end
          end
        end
        
        io << "  }\n"
      end
    end
  end
end
