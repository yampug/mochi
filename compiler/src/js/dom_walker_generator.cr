require "../tree-sitter/dependency_graph_generator"

module JS
  class DomWalkerGenerator
    def self.generate(paths : Array(Array(Int32)), root_name : String = "root") : String
      # TODO Optimization: Many paths share common prefixes.
      # could write a prefix tree but a simple direct traversal using firstChild and nextSibling per path for now

      String.build do |io|
        # sort paths so shorter paths might come first (optional polish)
        paths.sort_by { |p| p.size }.each do |path|
          next if path.empty?

          # We need to assign to this._dom_X_Y
          var_name = "this._dom_#{path.join('_')}"

          io << "    #{var_name} = #{root_name}"

          # Traverse the path using firstChild and nextSibling
          path.each do |index|
            io << ".firstChild"
            # For index N, we use nextSibling N times
            index.times do
              io << ".nextSibling"
            end
          end
          io << ";\n"
        end
      end
    end
  end
end
