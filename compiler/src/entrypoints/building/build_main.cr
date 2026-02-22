require "./builder_man"
require "file"
require "file_utils"
require "../../../../fragments/vendor/libpftrace/bindings/crystal/src/pftrace"
require "./trace_helper"

class BuildMain
  include TraceHelper

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
    keep_granular_build_artifacts : Bool,
    use_new_engine : Bool = false
  )
    trace = Pftrace::Trace.new("mochi_build.pftrace")
    start_time = Time.monotonic.total_nanoseconds.to_u64
    sequence_id = 1_u32

    trace.write_clock_snapshot(start_time)
    trace.write_process_descriptor(pid: Process.pid.to_i32, name: "MochiBuild", uuid: 100_u64)
    trace.write_thread_descriptor(pid: Process.pid.to_i32, tid: Process.pid.to_i32, name: "MainThread", uuid: 101_u64, parent_uuid: 100_u64)

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

    trace_slice(trace, "Setup", sequence_id, "build") do
      setup(builder_man)
    end

    print_separator
    transpiler = Compiler.new(use_new_engine)
    puts "5. Transpiling Mochi Components"

    mochi_comp_time = Time.measure do
      trace_slice(trace, "Transpiling", sequence_id, "build") do
        transpiler.transpile_directory("#{builder_man.pre_tp_dir}/lib", output_dir, builder_man, trace, sequence_id)
      end
    end
    puts "> Compilation took #{mochi_comp_time.total_milliseconds.to_i}ms"

    print_separator
    puts "6. Generating Opal Runtime"

    opal_rt_time = Time.measure do
      trace_slice(trace, "OpalRuntimeGen", sequence_id, "build") do
        opal_rt_gen = OpalRuntimeGenerator.new()
        opal_rt_gen.generate(builder_man.build_dir)
      end
    end
    puts "> Opal RT gen took #{opal_rt_time.total_milliseconds.to_i}ms"

    step_nr = 7

    print_separator
    puts "#{step_nr}. Bundling"
    step_nr += 1
    bundle_file_path = ""

    bundling_time_taken = Time.measure do
      trace_slice(trace, "Bundling", sequence_id, "build") do
        `cp "#{builder_man.build_dir}/runtime.js" "#{output_dir}/runtime.js"`
        `cp "#{builder_man.build_dir}/bundle.js" "#{output_dir}/bundle.js"`

        bundle_js = File.read("#{output_dir}/bundle.js")
        File.write("#{output_dir}/bundle.js", "#{bundle_js}\n#{JsLoggerGenerator.generate()}")
      end
    end
    puts "> Bundling took #{bundling_time_taken.total_milliseconds.to_i}ms"

    print_separator
    puts "#{step_nr}. Minify the output: #{with_mini}"
    step_nr += 1

    mini_time_taken = Time.measure do
      trace_slice(trace, "Minification", sequence_id, "build") do
        if with_mini
          unless Process.find_executable("swc")
            STDERR.puts "Error: swc is not installed. Please run 'npm install -g @swc/cli @swc/core'."
            exit 1
          end
          `npx swc "#{output_dir}/runtime.js" -o "#{output_dir}/runtime.js"`
        end
      end
    end
    puts "> Minification took #{mini_time_taken.total_milliseconds.to_i}ms"

    if !keep_granular_build_artifacts
      puts "removing granular build artifacts"

      remove_file("#{builder_man.build_dir}/ruby.js")
      remove_directory("#{builder_man.build_dir}/pre_tp")
      remove_directory("#{builder_man.build_dir}/src")
    end

    trace.close
    puts "Trace saved to mochi_build.pftrace"

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
