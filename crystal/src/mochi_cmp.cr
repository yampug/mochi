require "./webcomponents/web_component"

class MochiComponent
  property name : String
  property ruby_code : String
  property web_component : WebComponent
  property html : String
  property css : String
  
  def initialize(@name : String, @ruby_code : String, @web_component : WebComponent, @html : String, @css : String)
  end

  def to_s(io : IO)
    io << "MochiComponent(name: #{@name}, ruby_code: #{@ruby_code}, web_component: #{web_component}, html: #{html}, css: #{css})"
  end
end