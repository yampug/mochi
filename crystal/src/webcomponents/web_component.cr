class WebComponent
  property name : String
  property js_code : String

  def initialize(@name : String, @js_code : String)
  end

  def to_s(io : IO)
    io << "WebComponent(name: #{@name}, js_code: #{@js_code})"
  end
end