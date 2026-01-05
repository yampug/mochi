require "./builder_man"
require "file"
require "file_utils"

class BuildMain

  def setup(builder_man : BuilderMan)
    build_dir = builder_man.build_dir

    print_separator
    puts "2. Copying Ruby code to pre_tp"
    builder_man.copy_ruby_code_to_pre_tp
    puts "Ruby code copied to #{builder_man.pre_tp_dir}"
    # built-in components (need to be compiled)
    rb_rewriter = RubyRewriter.new

    builtin_feather_icon_comp = rb_rewriter.gen_builtin_component_feather_icon
    File.write("#{builder_man.pre_tp_dir}/lib/mochi_builtin_feathericon_comp.rb", builtin_feather_icon_comp)

    builtin_mochi_router = rb_rewriter.gen_builtin_mochi_router
    File.write("#{builder_man.pre_tp_dir}/lib/mochi_router.rb", builtin_mochi_router)

    builtin_route_comp = rb_rewriter.gen_builtin_route_component
    File.write("#{builder_man.pre_tp_dir}/lib/mochi_builtin_route_comp.rb", builtin_route_comp)

    print_separator
    puts "3. Copying pre_tp to src for transpilation"
    builder_man.copy_ruby_code_base

    print_separator
    puts "4. Packing in Batteries"
    batt_time = Time.measure do
      SorbetTypesBat.generate(builder_man.ruby_src_dir)
      CoreBattery.generate(builder_man.ruby_src_dir)
    end
    puts "> Batteries took #{batt_time.total_milliseconds.to_i}ms"

  end

  def build(
    input_dir : String,
    output_dir : String,
    parser : OptionParser,
    with_tc : Bool,
    with_mini : Bool,
    keep_granular_build_artifacts : Bool
  )

    # 1. Prepare Input / Output directories
    if input_dir.empty? || output_dir.empty?
      puts "Input & output directory need to be specified"
      exit 1
    end

    print_separator
    puts "1. input_dir:#{input_dir}, output_dir:#{output_dir}"
    builder_man = BuilderMan.new(input_dir)

    # steps 2-4
    puts "BuildID: #{builder_man.build_id}"
    puts "Working Dir: #{Dir.current}"
    setup(builder_man)

    print_separator
    transpiler = Compiler.new()
    puts "5. Transpiling Mochi Components"
    mochi_comp_time = Time.measure do
      transpiler.transpile_directory("#{builder_man.pre_tp_dir}/lib", output_dir, builder_man)
    end
    puts "> Compilation took #{mochi_comp_time.total_milliseconds.to_i}ms"

    print_separator
    puts "6. Generating Opal Runtime"
    opal_rt_time = Time.measure do
      opal_rt_gen = OpalRuntimeGenerator.new()
      opal_rt_gen.generate(builder_man.build_dir)
    end
    puts "> Opal RT gen took #{opal_rt_time.total_milliseconds.to_i}ms"

    step_nr = 7

    print_separator
    puts "#{step_nr}. Bundling"
    step_nr += 1
    bundle_file_path = ""
    bundling_time_taken = Time.measure do
      `cp "#{builder_man.build_dir}/runtime.js" "#{output_dir}/runtime.js"`
      `cp "#{builder_man.build_dir}/bundle.js" "#{output_dir}/bundle.js"`

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

        `npx swc "#{output_dir}/runtime.js" -o "#{output_dir}/runtime.js"`
      end
    end
    puts "> Minification took #{mini_time_taken.total_milliseconds.to_i}ms"

    if !keep_granular_build_artifacts
      puts "removing granular build artifacts"

      remove_file("#{builder_man.build_dir}/ruby.js")
      remove_directory("#{builder_man.build_dir}/pre_tp")
      remove_directory("#{builder_man.build_dir}/src")
    end

    print_separator
    puts "Done."
  end

  def remove_file(file_path : String)
    begin
      File.delete(file_path)
    rescue Exception
      puts "Unable to remove file, as I couldnt find it: #{file_path}"
    end
  end

  def remove_directory(dir_path : String)
    if dir_path.size > 5 # safety guard so nobody pipes sth like "/" in there
      begin
        FileUtils.rm_rf(dir_path)
      rescue e : Exception
        puts "Unable to remove directory #{dir_path}: #{e.message}"
      end
    end
  end
end
