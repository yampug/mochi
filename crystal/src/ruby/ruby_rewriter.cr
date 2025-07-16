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
  
  def format_require_path(path : String) : String
    path
      .sub(/^lib\//, "")
      .sub(/\.rb$/, "")
  end
  
  def gen_mochi_ruby_root(components : Array(MochiComponent)) : String
    rb_code = ""
    
    rb_code += "require 'opal'\n"
    rb_code += "require 'native'\n"
    rb_code += "require 'promise'\n"
    rb_code += "require 'browser/setup/full'\n"

    components.each do |mochi_comp|
      lib_path = extract_lib_path(mochi_comp.absolute_path)
      if lib_path
        rb_code += "require \"#{format_require_path(lib_path)}\"\n"
      end
    end
    
    rb_code += "class Root\n"
    rb_code += "end\n"
    
    
    # rb_code += "puts \"Rootv2 loaded.\"\n"
    rb_code += "\n"
    components.each do |mochi_comp|
      rb_code += "#{mochi_comp.name}.new\n"
    end
    
    # rb_code += "$document.ready do\n"
    # rb_code += "  puts \"Hello World from opal-browser\"\n"
    # rb_code += "end\n"
    
    rb_code
  end
  
  
  def comment_out_sorbet_signatures(ruby_code : String) : String
    ruby_code.each_line.map do |line|
      if line.strip.starts_with?("sig {")
        "#" + line
      else
        line
      end
    end.join("\n")
  end
  
  def comment_out_all_sorbet_signatures_in_dir(path : String)
    unless File.directory?(path)
      STDERR.puts "Error: Provided path is not a directory -> #{path}"
      return
    end
    
    Dir.each_child(path) do |child|
      full_path = File.join(path, child)
  
      if File.directory?(full_path)
        comment_out_all_sorbet_signatures_in_dir(full_path)
      elsif File.file?(full_path)
        begin
          content = File.read(full_path)
          File.write(full_path, comment_out_sorbet_signatures(content))
        rescue ex
          STDERR.puts "  -> Could not write to file: #{full_path}. Reason: #{ex.message}"
        end
      end
    end
  end
  
end