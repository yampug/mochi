require "./builder_man"

class BuildMain

  def build(
    input_dir : String,
    output_dir : String,
    parser : OptionParser,
    with_tc : Bool,
    with_mini : Bool)

    transpiler = Compiler.new()
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

    print_separator
    puts "5. Transpiling Mochi Components"
    mochi_comp_time = Time.measure do
      transpiler.transpile_directory("#{builder_man.pre_tp_dir}/lib", output_dir, builder_man)
    end
    puts "> Compilation took #{mochi_comp_time.total_milliseconds.to_i}ms"

    print_separator
    puts "6. Generating Opal Runtime"
    opal_rt_time = Time.measure do
      opal_rt_gen = OpalRuntimeGenerator.new()
      opal_rt_gen.generate(build_dir)
    end
    puts "> Opal RT gen took #{opal_rt_time.total_milliseconds.to_i}ms"

    step_nr = 7

    if with_tc
      print_separator
      puts "#{step_nr}. Running typechecks"
      step_nr += 1
      tc_time = Time.measure do
        #`cd #{builder_man.ruby_src_dir} && bundle install`
        # Using srb init might still be useful to generate RBIs, but it's slow.
        # For now, we keep it to ensure compatibility.
        #`cd #{builder_man.ruby_src_dir} && export SRB_YES=1 && srb init`

        begin
          session = Sorbet::Session.new(
          root_dir: builder_man.ruby_src_dir,
          multi_threaded: true
          )

          # Find all Ruby files in the source directory
          files = Dir.glob(File.join(builder_man.ruby_src_dir, "**", "*.rb"))
          result = session.typecheck_files(files)

          if result.success?
            puts "✓ No type errors found!"
          else
            puts "✗ Found #{result.errors.size} errors:"
            result.errors.each do |error|
              puts "  #{error}"
            end
          end

          session.close
          rescue ex
            puts "Error running Sorbet session: #{ex.message}"
        end
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
end
