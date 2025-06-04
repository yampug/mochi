require "file_utils"
require "path"
require "json"
require "./ruby/ruby_endable_statement"
require "./ruby/ruby_def"
require "./bind_extractor"
require "./ruby/ruby_understander"
require "./webcomponents/web_component_generator"
require "./webcomponents/web_component"
require "./mochi_cmp"

require "option_parser"



def transpile_directory(input_dir : String, output_dir : String)
  puts "inputDir:'#{input_dir}', outDir:'#{output_dir}'"


  components = [] of MochiComponent
  Dir.glob(Path[input_dir, "**", "*.mo.rb"].to_s) do |path|
    if File.file?(path) && path.ends_with?(".mo.rb")
      begin
        puts "Processing #{path}"
        content = File.read(path)
        absolute_path = Path[path].expand.to_s
        #translations[absolute_path] = content
        puts "Read: #{absolute_path}"
        rb_file = File.read(absolute_path)
        component = transpile_component(rb_file)
        if component
          components << component
        end
        
        
      rescue ex
        puts "Error reading file #{path}: #{ex.message}"
      end
    end
  end
  total_ruby_code = get_all_ruby_code(components)
  total_js_code = ""
  
  components.each do |mochi_comp|
    #             totalJsCode.appendLine(component.webComponent.jsCode)

    total_js_code = mochi_comp.web_component.js_code + "\n"
  end
  work_dir_path = "../mo_build_cr"
  
  maybe_create_clear_output_dir(work_dir_path)


  File.write("../mo_build_cr/total_ruby.rb", total_ruby_code)
  
  `opal -cO ../mo_build_cr/total_ruby.rb -o ../mo_build_cr/total_ruby.js --no-source-map`
  # TODO output
  compiled_rb_code = File.read("../mo_build_cr/total_ruby.js")
  
  output = compiled_rb_code + "\n" + total_js_code
  puts "Writing #{output_dir}/components.js"
  File.write("#{output_dir}/components.js", output)
  
end

def get_all_ruby_code(components : Array(MochiComponent)) : String
  ruby_code = ""
  components.each do |mochi_comp|
    ruby_code = ruby_code + (mochi_comp.ruby_code)
  end
  return ruby_code
end


def maybe_create_clear_output_dir(work_dir_path : String)
  if !Dir.exists?(work_dir_path)
    Dir.mkdir(work_dir_path)
  else
    # empty directory
    Dir.each_child(work_dir_path) do |entry|
      path = File.join(work_dir_path, entry)
      if File.directory?(path)
        FileUtils.rm_rf(path)
      else
        File.delete(path)
      end
    end
  end
end

def transpile_component(rb_file : String)
  cls_name = RubyUnderstander.class_name(rb_file)
  puts "ClassName:'#{cls_name}'"

  methods = RubyUnderstander.extract_method_bodies(rb_file, cls_name)
  #puts methods

  amped_ruby_code = rb_file
  if methods.has_key?("css")

    #css = methods["css"]
    #puts "css:#{css.body[1...css.body.size - 1]}"
    css = RubyUnderstander.extract_raw_string_from_def_body(methods["css"].body, "css")
    html = RubyUnderstander.extract_raw_string_from_def_body(methods["html"].body, "html")
    reactables = RubyUnderstander.extract_raw_string_from_def_body(methods["reactables"].body, "reactables")
    puts "reactables:'#{reactables}'"
    
    reactables_arr = js_to_cr_array(reactables)
    reactables_arr.each do |item|
      puts "Item: #{item}"
    end
    bindings = BindExtractor.extract(html)
    cmp_name = RubyUnderstander.get_cmp_name(rb_file, cls_name)
    
    puts "---------------------------------------------------"
    
    if cmp_name
      # add getters & setters to the ruby class
      reactables_arr.each do |reactable|
        var_name = reactable
        second_last_index = find_second_last_index(amped_ruby_code, "end")
      
        if second_last_index
          insertion_point = second_last_index + 3
          # add getter
          getter_code_to_insert = "\n\n\tdef get_#{var_name}\n\t\t@#{var_name}\n\tend\n"
          amped_ruby_code = amped_ruby_code[0...insertion_point] + getter_code_to_insert + amped_ruby_code[insertion_point..-1]
          
          # add setter
          setter_code_to_insert = "\n\n\tdef set_#{var_name}(value)\n\t\t@#{var_name} = value\n\tend\n"
          amped_ruby_code = amped_ruby_code[0...insertion_point] + setter_code_to_insert + amped_ruby_code[insertion_point..-1]
        end
      end      
      web_comp_generator = WebComponentGenerator.new
      
      web_component = web_comp_generator.generate(
        mochi_cmp_name = cls_name, 
        tag_name = cmp_name.not_nil!,
        css,
        html = bindings.html.not_nil!,
        reactables,
        bindings.bindings
      )
      
      return MochiComponent.new(
        cls_name,
        ruby_code = amped_ruby_code,
        web_component,
        html,
        css
      )
    end
  end
end

def find_second_last_index(text : String, substring_to_find : String) : Int32?
  last_idx = text.rindex(substring_to_find)
  
  unless last_idx && last_idx > 0
    return -1
  end
  # at this point, last_idx is a non-nil Int32 and last_idx > 0
  second_last_idx = text.rindex(substring_to_find, last_idx - 1)
  return second_last_idx
end

def js_to_cr_array(json_array_str : String) : Array(String) 
  parsed_array = JSON.parse(json_array_str).as_a
  string_array = parsed_array.map(&.as_s)
  return string_array
end

puts "Mochi v0.1"

input_dir = ""
output_dir = ""

OptionParser.parse do |parser|
  parser.banner = "Usage: mochi [options]"

  parser.on("-i IN_DIR", "--input_dir=IN_DIR", "Input directory to read from") do |i|
    input_dir = i
  end

  parser.on("-o OUT_DIR", "--output_dir=OUT_DIR", "Ouput directory to write into") do |o|
    output_dir = o
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  # Handle cases where a required argument for an option is missing
  parser.missing_option do |flag|
    STDERR.puts "ERROR: Missing argument for #{flag}"
    STDERR.puts parser
    exit 1
  end

  # Handle unknown options
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: Unknown option: #{flag}"
    STDERR.puts parser
    exit 1
  end
end
puts "input_dir:#{input_dir}, output_dir:#{output_dir}"

transpile_directory("../ruby/lib", "../devground")

