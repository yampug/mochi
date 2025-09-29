require "file_utils"
require "path"
require "json"
require "option_parser"
require "random"
require "time"

require "./ruby/ruby_endable_statement"
require "./ruby/ruby_def"
require "./bind_extractor"
require "./ruby/ruby_understander"
require "./ruby/ruby_rewriter"
require "./webcomponents/web_component_generator"
require "./webcomponents/web_component"
require "./mochi_cmp"
require "./opal/opal_runtime_generator"
require "./builder_man"
require "./initializer"

require "./batteries/sorbet_types_battery"
require "./batteries/core_battery"
require "./js/js_logger"

def transpile_directory(input_dir : String, output_dir : String, builder_man : BuilderMan)
  build_dir = builder_man.build_dir
  puts "inputDir:'#{input_dir}', outDir:'#{output_dir}', build_dir:'#{build_dir}'"

  components = [] of MochiComponent
  i = 1
  rb_rewriter = RubyRewriter.new

  nr_files = 0
  done_channel = Channel(Nil).new

  Dir.glob(Path[input_dir, "**", "*.rb"].to_s) do |path|
    if File.file?(path) && path.ends_with?(".rb")
      nr_files += 1
      spawn do
        begin
          puts "Processing #{path}"
          content = File.read(path)
          absolute_path = Path[path].expand.to_s
  
          rb_file = File.read(absolute_path)
          component = transpile_component(rb_file, i, absolute_path)
  
          i += 1
          if component
            components << component
  
            # replace ruby code with amplified version
            src_dir = builder_man.ruby_src_dir
            lib_path = rb_rewriter.extract_lib_path(absolute_path)
            file_path = "#{src_dir}/#{lib_path}"
            puts "lib_path:#{lib_path}, src_dir:#{src_dir}, file_path:#{file_path}"
            File.write(file_path, component.ruby_code)
          end
          done_channel.send(nil)
        end
      rescue ex
        puts "Error reading file #{path}: #{ex.message}"
      end
    end

  end
  
  nr_files.times do |i|
    done_channel.receive
  end
  
  # comment out Sorbet signatures
  rb_rewriter.comment_out_all_sorbet_signatures_in_dir("#{builder_man.ruby_src_dir}/lib")

  mochi_root = rb_rewriter.gen_mochi_ruby_root(components)
  File.write("#{builder_man.ruby_src_dir}/lib/Root.rb", mochi_root)

  puts "Done with preparing components for transpilation"
  puts "Transpiling..."
  transpiled_ruby_code_path = "#{build_dir}/ruby.js"
  `cd #{builder_man.ruby_src_dir} && bundler install`
  puts "gems installed"
  `cd #{builder_man.ruby_src_dir} && opal -I ./lib -cO -s opal -s native -s promise -s browser/setup/full -s sorbet-runtime ./lib/Root.rb -o #{transpiled_ruby_code_path} --no-source-map --no-method-missing`
  transpiled_ruby_code = File.read(transpiled_ruby_code_path)

  # assemble the js code (webcomponents etc)
  components_js_code = ""
  components.each do |mochi_comp|
    components_js_code = components_js_code + "\n" + mochi_comp.web_component.js_code + "\n"
  end
  components_js_code = components_js_code + "\n" + "console.log('Mochi booted.');" + "\n"

  output = transpiled_ruby_code + "\n" + components_js_code
  puts "Writing #{build_dir}/components.js"
  File.write("#{build_dir}/components.js", output)
  puts "Transpilation finished"

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

def transpile_component(rb_file : String, i : Int32, absolute_path : String)
  cls_name = RubyUnderstander.class_name(rb_file)

  print_cmp_start_separator(cls_name, i)
  puts "ClassName:'#{cls_name}'"

  if cls_name.blank?
    return
  end

  methods = RubyUnderstander.extract_method_bodies(rb_file, cls_name)
  #puts methods

  amped_ruby_code = rb_file
  if methods.has_key?("css")

    #css = methods["css"]
    #puts "css:#{css.body[1...css.body.size - 1]}"
    imports = RubyUnderstander.get_imports(rb_file)
    css = RubyUnderstander.extract_raw_string_from_def_body(methods["css"].body, "css")
    html = RubyUnderstander.extract_raw_string_from_def_body(methods["html"].body, "html")
    reactables = RubyUnderstander.extract_raw_string_from_def_body(methods["reactables"].body, "reactables")
    # puts "reactables:'#{reactables}'"

    reactables_arr = js_to_cr_array(reactables)
    reactables_arr.each do |item|
      # puts "Item: #{item}"
    end
    bindings = BindExtractor.extract(html)
    tag_name = RubyUnderstander.get_cmp_name(rb_file, cls_name)


    if tag_name
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
        tag_name = tag_name.not_nil!,
        css,
        html = bindings.html.not_nil!,
        reactables,
        bindings.bindings
      )

      print_cmp_end_seperator(cls_name, i)
      # puts no_types_ruby_code
      return MochiComponent.new(
        absolute_path,
        cls_name,
        imports,
        ruby_code = amped_ruby_code,
        web_component,
        html,
        css
      )
    end
  else
    puts "Skipping '#{cls_name}', no css method"
  end
  print_cmp_end_seperator(cls_name, i)
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

def generate_build_id : String
  random_part = Random.new.hex(16)
  time_part = Time.utc.to_unix_ns
  return "#{random_part}#{time_part}"
end

def print_cmp_start_separator(tag_name : String, i : Int32)
  puts "==============================  (#{i})  START   #{tag_name}   =================================="
end

def print_cmp_end_seperator(tag_name : String, i : Int32)
  puts "==============================  (#{i})   END   #{tag_name}   ===================================="
end

def print_separator
  puts "------------------------------------------------------------------------------------"
end

puts "Mochi v0.1cd"

project_name = ""
input_dir = ""
output_dir = ""
with_mini = false
with_tc = false

parser = OptionParser.new
OptionParser.parse do |p|
  p.banner = "Usage: mochi [options]"
  
  p.on("-init PROJ_NAME", "--initialize=PROJ_NAME", "Initialize a new mochi project") do |k|
    project_name = k
  end

  p.on("-i IN_DIR", "--input_dir=IN_DIR", "Input directory to read from") do |i|
    input_dir = i
  end

  p.on("-o OUT_DIR", "--output_dir=OUT_DIR", "Ouput directory to write into") do |o|
    output_dir = o
  end

  p.on("-m", "--mini", "Minimize output") do |o|
    with_mini = true
  end

  p.on("-tc", "--typecheck", "Run typechecks with Sorbet") do |o|
    with_tc = true
  end

  p.on("-h", "--help", "Show this help") do
    puts p
    exit
  end

  # Handle cases where a required argument for an option is missing
  p.missing_option do |flag|
    STDERR.puts "ERROR: Missing argument for #{flag}"
    STDERR.puts p
    exit 1
  end

  # Handle unknown options
  p.invalid_option do |flag|
    STDERR.puts "ERROR: Unknown option: #{flag}"
    STDERR.puts p
    exit 1
  end

  parser = p
end

if !project_name.empty?  
  Initializer.new(project_name)
else
  # 1. Prepare Input / Output directories
  if input_dir.empty? || output_dir.empty?
    puts parser
    exit 1
  end
  
  print_separator
  puts "1. input_dir:#{input_dir}, output_dir:#{output_dir}"
  builder_man = BuilderMan.new(input_dir)
  puts "BuildID: #{builder_man.build_id}"
  puts "Working Dir: #{Dir.current}"
  build_dir = builder_man.build_dir
  builder_man.copy_ruby_code_base
  
  print_separator
  puts "2. Packing in Batteries"
  batt_time = Time.measure do
    SorbetTypesBat.generate(builder_man.ruby_src_dir)
    CoreBattery.generate(builder_man.ruby_src_dir)
  end
  puts "> Batteries took #{batt_time.total_milliseconds.to_i}ms"
  
  print_separator
  puts "3. Transpiling Mochi Components"
  mochi_comp_time = Time.measure do
    transpile_directory("#{input_dir}/lib", output_dir, builder_man)
  end
  puts "> Compilation took #{mochi_comp_time.total_milliseconds.to_i}ms"
  
  print_separator
  puts "4. Generating Opal Runtime"
  opal_rt_time = Time.measure do
    opal_rt_gen = OpalRuntimeGenerator.new()
    opal_rt_gen.generate(build_dir)
  end
  puts "> Opal RT gen took #{opal_rt_time.total_milliseconds.to_i}ms"
  
  step_nr = 5
  
  if with_tc
    print_separator
    puts "#{step_nr}. Running typechecks"
    step_nr += 1
    tc_time = Time.measure do  
      `cd #{builder_man.ruby_src_dir} && bundle install`
      `cd #{builder_man.ruby_src_dir} && export SRB_YES=1 && srb init`
      puts ""
      puts "Typecheck Results:"
      `cd #{builder_man.ruby_src_dir} && srb tc`
    end
    puts "> Sorbet Typecheck took #{tc_time.total_milliseconds.to_i}ms"
  end
  
  
  print_separator
  puts "#{step_nr}. Bundling"
  step_nr += 1
  bundle_file_path = ""
  bundling_time_taken = Time.measure do
  
    `cp "#{build_dir}/opal-runtime.js" "#{output_dir}/opal-runtime.js"`
    `cp "#{build_dir}/components.js" "#{output_dir}/bundle.js"`

    bundle_js = File.read("#{output_dir}/bundle.js")

    # bundle in js batteries
    File.write("#{output_dir}/bundle.js", "#{bundle_js}\n#{JsLoggerGenerator.generate()}")
  end
  puts "> Bundling took #{bundling_time_taken.total_milliseconds.to_i}ms"
  
  
  # check swc is installed
  print_separator
  puts "#{step_nr}. Minify the output: #{with_mini}"
  step_nr += 1
  mini_time_taken = Time.measure do
  
    if with_mini
      unless Process.find_executable("swc")
        STDERR.puts "Error: swc is not installed. Please run 'npm install -g @swc/cli @swc/core'."
        exit 1
      end
  
      `npx swc "#{output_dir}/opal-runtime.js" -o "#{output_dir}/opal-runtime.js"`
    end
  end
  puts "> Minification took #{mini_time_taken.total_milliseconds.to_i}ms"
  
  
  print_separator
  puts "Done."

end

