class EventArgumentExtractor
  def self.process(html : String) : String
    # Look for attributes like onclick="{method(arg1, arg2)}"
    # We want to convert this into:
    # onclick="{method}" data-mochi-arg-0="{arg1}" data-mochi-arg-1="{arg2}"
    
    # Regex finds standard event handlers (e.g. onclick, onchange, onsubmit) 
    # that have parentheses inside the {} block
    regex = /(on[a-z]+)\s*=\s*(["'])?\{([a-zA-Z0-9_\-\:]+)\s*\((.*?)\)\}\2?/m
    
    processed_html = html.gsub(regex) do |match, m|
      event_name = m[1]
      method_name = m[3]
      args_string = m[4]
      
      # If no arguments were between the (), keep it clean
      if args_string.strip.empty?
        "#{event_name}=\"{#{method_name}}\""
      else
        # Split arguments by comma (simplistic for now, assuming no nested method calls containing commas)
        args = args_string.split(",").map(&.strip).reject(&.empty?)
        
        replacement = "#{event_name}=\"{#{method_name}}\""
        
        args.each_with_index do |arg, index|
          if arg == "$event" || arg == "$element"
            replacement += " data-mochi-arg-#{index}=\"#{arg}\""
          else
            replacement += " data-mochi-arg-#{index}=\"{#{arg}}\""
          end
        end
        
        replacement
      end
    end

    processed_html
  end
end
