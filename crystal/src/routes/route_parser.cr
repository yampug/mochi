# require "yaml"
# require "./route"

# class RouteParser

#     def self.parse(raw_str : String) : Array(Route)
#         result = [] of Route
#         yaml = YAML.parse(raw_str)

#         routes_node = yaml["routes"]?
#         if routes_node
#             routes_array = routes_node.as_a

#             routes_array.each do |route_entry|
#                 route_entry.as_h.each do |route_name, properties|
#                     if properties
#                         envs : Array(String) = [] of String
#                         path : String = ""
#                         component : String = ""
#                         kind : String = ""
#                         vars : Hash(String, String) = {} of String => String

#                         properties.as_a.each do |property|
#                             property.as_h.each do |key, value|
#                                 if key == "envs"
#                                     envs = value.as_s.split(",").map(&.strip)
#                                 end
#                                 if key == "path"
#                                     path = value.as_s
#                                 end
#                                 if key == "component"
#                                     component = value.as_s
#                                 end
#                                 if key == "kind"
#                                     kind = value.as_s
#                                 end
#                                 if key == "vars"
#                                     # vars is an array of hashes, convert to a single hash
#                                     value.as_a.each do |var_item|
#                                         var_item.as_h.each do |var_key, var_value|
#                                             vars[var_key.as_s] = var_value.as_s
#                                         end
#                                     end
#                                 end
#                             end
#                         end

#                         # validation required fields are there
#                         if envs.empty?
#                             raise "Route '#{route_name}' is missing required field: envs"
#                         end
#                         if path.empty?
#                             raise "Route '#{route_name}' is missing required field: path"
#                         end
#                         if component.empty?
#                             raise "Route '#{route_name}' is missing required field: component"
#                         end

#                         route = Route.new(envs, route_name.as_s, path, kind, component, vars)
#                         result.push(route)
#                     end
#                 end
#             end
#         else
#             puts "No routes defined in routes.yaml"
#         end
#         return result
#     end

# end