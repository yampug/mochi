require "../html/conditional_processor"

module JS
  class ConditionalBlockGenerator
    def self.generate(block : ConditionalBlock, component_name : String, paths : Hash(Int32, Array(Int32))) : String
      var_name = "this._if_anchor_#{block.id}"
      path = paths[block.id]?
      
      # We need to find the element path dynamically passed in through args
      walker = path ? "this._dom_#{path.join('_')}" : var_name
      template_id = "#{component_name}_if_#{block.id}"
      
      # Note: JS Kernel expects simple signals for now, 
      # so condition expects a function evaluation that executes within createEffect
      
      <<-JS
      this.onCleanup(
        createEffect(() => {
          let visible = #{block.condition};
          if (visible && !#{var_name}_rendered) {
            let frag = _mochi_templates['#{template_id}'].content.cloneNode(true);
            #{var_name}_rendered = Array.from(frag.childNodes);
            #{walker}.parentNode.insertBefore(frag, #{walker}.nextSibling);
          } else if (!visible && #{var_name}_rendered) {
            #{var_name}_rendered.forEach(n => n.remove());
            #{var_name}_rendered = null;
          }
        })
      );
      JS
    end
    
    def self.generate_walker(block : ConditionalBlock, paths : Hash(Int32, Array(Int32)), root_name : String = "root") : String
      path = paths[block.id]?
      return "" unless path
      
      var_name = "this._if_anchor_#{block.id}"
      
      String.build do |io|
        io << "    #{var_name} = #{root_name}"
        path.each do |index|
          io << ".firstChild"
          index.times { io << ".nextSibling" }
        end
        io << ";\n"
        io << "    let #{var_name}_rendered = null;\n"
      end
    end
  end
end
