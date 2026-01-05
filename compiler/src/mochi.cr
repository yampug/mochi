require "file_utils"
require "path"
require "json"
require "option_parser"
require "random"
require "time"

require "./ruby/ruby_endable_statement"
require "./ruby/ruby_def"
require "./bind_extractor"
require "./html/conditional_processor"
require "./ruby/conditional_method_generator"
require "./html/each_processor"
require "./ruby/each_method_generator"
require "./ruby/ruby_understander"
require "./ruby/ruby_rewriter"
require "./webcomponents/web_component_generator"
require "./webcomponents/web_component"
require "./mochi_cmp"
require "./opal/opal_runtime_generator"
require "./initializer"
require "./entrypoints/building/build_main"
require "./entrypoints/building/transpiler"
require "./entrypoints/typechecker"

require "./batteries/sorbet_types_battery"
require "./batteries/core_battery"
require "./sorbet/sorbet"
require "./js/js_logger"
require "./tooling/dev_server"

def self.get_attr(component, name) : String
  return `#{component}.element.getAttribute(#{name})`
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


project_name = ""
input_dir = ""
output_dir = ""
with_mini = false
with_tc = false
is_dev_server = false
dev_server_root = ""
dev_server_config_path = ""
is_standalone_typecheck = false
keep_granular_build_artifacts = false

desc_dev_server = "Launch dev server"

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

  p.on("--minimize", "Minimize output") do |o|
    with_mini = true
  end

  p.on("--typecheck", "Run typechecks with Sorbet") do |o|
    with_tc = true
  end

  p.on("typecheck", "typecheck the current directory") do
    is_standalone_typecheck = true
  end

  p.on("--keep_granular_build_artifacts", "Preserves all granular build artifacts (meant for developers working on Mochi)") do
    keep_granular_build_artifacts = true
  end
  p.on("-h", "--help", "Show this help") do
    puts p
    exit
  end

  p.on("--dev", desc_dev_server) do
    is_dev_server = true
  end

  p.on("dev", desc_dev_server) do
    is_dev_server = true
  end

  p.on("--root=ROOT_DIR", "Root directory for the dev server") do |root_dir|
    dev_server_root = root_dir
  end

  p.on("--config=DEV_CONFIG", "Path to dev server config file") do |config_path|
    dev_server_config_path = config_path
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

if is_dev_server
  if dev_server_config_path.size < 1 || dev_server_root.size < 1
    puts "No arguments provided, intended usage:".colorize(:red)
    puts "  mochi dev --config=</path/to/dev_server_config.json> --root=</path/to/ruby/src>"
    exit 1
  else
    dev_server = DevServer.new
    dev_server.start(dev_server_root, dev_server_config_path)
  end
else
  if is_standalone_typecheck
    if ARGV.empty?
      puts "No arguments provided, intended usage:".colorize(:red)
      puts "  mochi typecheck <path_to_ruby_code>"
      exit 1
    else
      Typechecker.new.typecheck ARGV[0]
    end
    exit 0
  end

  puts "Mochi v0.2"
  if !project_name.empty?
    Initializer.new(project_name)
  else
    BuildMain.new().build(
      input_dir,
      output_dir,
      parser,
      with_tc,
      with_mini,
      keep_granular_build_artifacts
    )
  end
end



