class RubyVariable
    property value : String
    property exported : Bool
  
    def initialize(@value : String, @exported : Bool)
    end
  
    def to_s(io : IO)
      io << "RubyVariable(value: #{@value.inspect}, exported: #{@exported})"
    end
  end