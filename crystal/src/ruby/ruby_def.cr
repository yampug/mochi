class RubyDef
    property name : String?
    property file_name : String
    property class_name : String
    property body : Array(String)
    property parameters : Array(String)
 
    def initialize(@name, @file_name, @class_name, @body, @parameters)
    end
 end