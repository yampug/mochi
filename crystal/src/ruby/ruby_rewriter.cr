class RubyRewriter

  def initialize
  end
  
  def rewrite : String
    ""
  end
  
  def extract_lib_path(path : String) : String?
  
    result = nil
    if index = path.index("lib/")
      # Take a slice from that index to the end of the string
      result = path[index..]
    end
    return result
  end
  
end