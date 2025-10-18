# class Route
#     property envs : Array(String)
#   property name : String
#   property path : String
#   property kind : String 
#   property component : String
#   property vars : Hash(String, String)
  
#   def initialize(@envs : Array(String), @name : String, @path : String, @kind : String, @component : String, @vars : Hash(String, String))
#   end

#   def to_s(io : IO)
#     io << "Route(envs: #{@envs}, name: #{@name}, path: #{@path}, component: #{@component}, vars: #{@vars})"
#   end
# end