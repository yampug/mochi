require "./../../quickjs"
require "./../../caching/cache"
require "../../../../fragments/vendor/libpftrace/bindings/crystal/src/pftrace"
require "./trace_helper"
require "../../webcomponents/new_component_generator"
require "../../tree-sitter/instance_var_analyzer"
require "../../html/attribute_conditional_extractor"
require "../../html/attribute_hash_extractor"
require "../../html/event_argument_extractor"
require "../../ruby/attribute_method_generator"
require "../../ruby/attribute_hash_generator"

class Compiler
  include TraceHelper

  def initialize()
  end

  def transpile_directory(input_dir : String, output_dir : String, builder_man : BuilderMan, trace : Pftrace::Trace? = nil, sequence_id : UInt32 = 1_u32)
    build_dir = builder_man.build_dir
    puts "inputDir:'#{input_dir}', outDir:'#{output_dir}', build_dir:'#{build_dir}'"

    components = [] of MochiComponent
    i = 1
    rb_rewriter = RubyRewriter.new

    nr_files = 0
    done_channel = Channel(Nil).new

    trace_slice(trace, "ProcessComponents", sequence_id) do
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

                src_dir = builder_man.ruby_src_dir
                lib_path = rb_rewriter.extract_lib_path(absolute_path)
                file_path = "#{src_dir}/#{lib_path}"
                puts "lib_path:#{lib_path}, src_dir:#{src_dir}, file_path:#{file_path}"
                File.write(file_path, component.ruby_code)
              end
              done_channel.send(nil)
            end
            rescue ex
              puts "Error processing file #{path}: #{ex.message}\n#{ex.inspect_with_backtrace}"
          end
        end
      end

      nr_files.times do |i|
        done_channel.receive
      end
    end

    trace_slice(trace, "SorbetSignatures", sequence_id) do
      rb_rewriter.comment_out_all_sorbet_signatures_in_dir("#{builder_man.ruby_src_dir}/lib")
    end

    trace_slice(trace, "GenerateRoot", sequence_id) do
      mochi_root = rb_rewriter.gen_mochi_ruby_root(components)
      File.write("#{builder_man.ruby_src_dir}/lib/Root.rb", mochi_root)
    end


    puts "Done with preparing components for transpilation"
    puts "Transpiling..."
    transpiled_ruby_code_path = "#{build_dir}/ruby.js"
    # `cd #{builder_man.ruby_src_dir} && bundler install`
    puts "gems installed (skipped)"

    use_quickjs = true

    cache = Cache.new

    transpiled_ruby_code = trace_slice(trace, "QuickJSCompilation", sequence_id) do
      if use_quickjs
        builder = trace_slice(trace, "BuilderSetup", sequence_id) do
          b = trace_slice(trace, "BuilderInit", sequence_id) do
            QuickJS::Opal::Builder.new(include_runtime: false)
          end

          trace_slice(trace, "AddStdlibAwait", sequence_id) { b.add_stdlib("await") }
          trace_slice(trace, "AddStdlibJson", sequence_id) { b.add_stdlib("json") }

          b.add_raw_js("Opal.modules['sorbet-runtime'] = function(Opal) { return Opal.nil; };")
          b.add_raw_js("Opal.modules['sorbet'] = function(Opal) { return Opal.nil; };")

          trace_slice(trace, "CompileLibSetup", sequence_id) do
            b.compile("$LOAD_PATH.unshift('/lib'); $LOAD_PATH.unshift('lib'); $LOAD_PATH.unshift('./lib')", "lib_setup")
          end

          b.add_raw_js("Opal.load('lib_setup');")
          b
        end

        lib_dir = "#{builder_man.ruby_src_dir}/lib"
        src_dir = builder_man.ruby_src_dir
        puts "Scanning #{lib_dir} for source files..."

        trace_slice(trace, "CompileSourceFiles", sequence_id) do
          if Dir.exists?(lib_dir)
            Dir.glob("#{lib_dir}/**/*.rb") do |full_path|
              next if full_path.ends_with?("/Root.rb")

              code = File.read(full_path)
              rel_path_src = Path[full_path].relative_to(src_dir).to_s
              rel_path_lib = Path[full_path].relative_to(lib_dir).to_s

              if rel_path_lib == "mochi.rb"
                builder.compile_with_cache(code, rel_path_src, cache)
                builder.compile_with_cache(code, rel_path_lib, cache)
              elsif rel_path_lib.starts_with?("sorbet-types/")
                builder.compile_with_cache(code, rel_path_src, cache)
              else
                builder.compile_with_cache(code, rel_path_lib, cache)
              end
            end
          else
            puts "ERROR: lib_dir does not exist: #{lib_dir}"
          end
        end

        puts "Compiling Entry Point: lib/Root.rb (as main)"

        trace_slice(trace, "CompileEntryPoint", sequence_id) do
          root_path = "#{lib_dir}/Root.rb"
          if File.exists?(root_path)
            builder.compile_with_cache(File.read(root_path), "lib/Root.rb", cache, requirable: false)
          else
            puts "ERROR: Root.rb not found at #{root_path}"
          end
        end

        result = trace_slice(trace, "BuildOutput", sequence_id) do
          builder.build(nil)
        end

        File.write(transpiled_ruby_code_path, result)
        builder.finalize
        result
      else
        puts "Using Opal CLI (Old Logic)..."
        `cd #{builder_man.ruby_src_dir} && opal -I ./lib -cO -s opal -s native -s promise -s browser/setup/full -s sorbet-runtime ./lib/Root.rb -o #{transpiled_ruby_code_path} --no-source-map --no-method-missing`
        File.read(transpiled_ruby_code_path)
      end
    end

    cache.close

    trace_slice(trace, "AssembleJS", sequence_id) do
      components_js_code = ""
      components.each do |mochi_comp|
        components_js_code = components_js_code + "\n" + mochi_comp.web_component.js_code + "\n"
      end
      components_js_code = components_js_code + "\n" + "console.log('Mochi booted.');" + "\n"

      output = transpiled_ruby_code + "\n" + components_js_code
      puts "Writing #{build_dir}/bundle.js"
      File.write("#{build_dir}/bundle.js", output)
    end

    puts "Transpilation finished"

  end

  private def transpile_component(rb_file : String, i : Int32, absolute_path : String)
    cls_name = RubyUnderstander.class_name(rb_file)

    print_cmp_start_separator(cls_name, i)
    puts "ClassName:'#{cls_name}'"

    if cls_name.blank?
      return
    end

    methods : Hash(String, RubyDef) = RubyUnderstander.extract_method_bodies(rb_file, cls_name)
    #puts methods

    amped_ruby_code = rb_file
    if methods.has_key?("css")

    #css = methods["css"]
    #puts "css:#{css.body[1...css.body.size - 1]}"
      imports = RubyUnderstander.get_imports(rb_file)
      css = RubyUnderstander.extract_raw_string_from_def_body(methods["css"].body, "css")
      html = RubyUnderstander.extract_raw_string_from_def_body(methods["html"].body, "html")

      # 1. Extract hash attributes BEFORE anything else (since {{...}} breaks Lexbor parsing)
      attr_hash_result = AttributeHashExtractor.process(html)
      html = attr_hash_result.html

      amped_ruby_code = AttributeHashGenerator.inject_methods_into_class(
        amped_ruby_code,
        cls_name,
        attr_hash_result.hashes
      )

      # 2. Extract attribute conditionals
      attr_cond_result = AttributeConditionalExtractor.process(html)
      html = attr_cond_result.html

      amped_ruby_code = AttributeMethodGenerator.inject_methods_into_class(
        amped_ruby_code,
        cls_name,
        attr_cond_result.conditionals
      )

      # 3. Extract event handler arguments into data- attributes
      html = EventArgumentExtractor.process(html)

      # Analyze instance variables to determine reactables automatically
      vars = TreeSitter::InstanceVarAnalyzer.analyze(rb_file)

      # Filter for variables that are either:
      # - Bound in the HTML (used in {}) AND are actual state (written/mutated)
      # - Mutated via attr_accessor/attr_writer
      # - Written to outside of the constructor (state)
      reactive_vars = vars.select do |v|
        (v.is_bound && (v.writes > 0 || v.attr_mutated)) || v.attr_mutated || v.written_outside_constructor
      end

      reactables_arr = reactive_vars.map { |v| v.name.sub(/^@/, "") }

      # Add the new attribute conditionals and hashes to reactables so they are tracked
      attr_cond_result.conditionals.each do |cond|
        reactables_arr << "__mochi_attr_cond_#{cond.id}"
      end
      attr_hash_result.hashes.each do |hash_cond|
        reactables_arr << "__mochi_attr_hash_#{hash_cond.id}"
      end

      # puts "Computed reactables for #{cls_name}: #{reactables_arr}"
      reactables = if reactables_arr.empty?
                     "[]"
                   else
                     "['#{reactables_arr.join("', '")}']"
                   end

      # puts "reactables: #{reactables}"

      conditional_result = ConditionalProcessor.process(html)

      amped_ruby_code = ConditionalMethodGenerator.inject_methods_into_class(
      amped_ruby_code,
      cls_name,
      conditional_result.conditionals
      )

      each_result = EachProcessor.process(conditional_result.html)

      amped_ruby_code = EachMethodGenerator.inject_methods_into_class(
      amped_ruby_code,
      cls_name,
      each_result.each_blocks
      )

      bindings = BindExtractor.extract(each_result.html)
      tag_name = RubyUnderstander.get_cmp_name(rb_file, cls_name)


      if tag_name
        # Build all methods to inject (getters, setters, and internal mounted bridge)
        injected_methods = [] of String
        injected_methods << "def __mochi_mounted(shadow, el); @element = el; end"

        reactables_arr.each do |var_name|
          if var_name.starts_with?("__mochi_attr_cond_") || var_name.starts_with?("__mochi_attr_hash_")
            injected_methods << "def get_#{var_name}; #{var_name}(); end"
            injected_methods << "def set_#{var_name}(value); end"
          else
            injected_methods << "def get_#{var_name}; @#{var_name}; end"
            injected_methods << "def set_#{var_name}(value); @#{var_name} = value; `\#{@element}.update_#{var_name}(\#{value})` if @element; end"
          end
        end

        # TODO remove - hacky injection of cross-component Event Bus APIs
        injected_methods << <<-RUBY
        def emit(event_name, payload = nil)
          `window.Mochi.emit(\#{event_name.to_s}, \#{payload.to_n})`
        end

        def on(event_name, &block)
          @_mochi_subscriptions ||= []
          @_mochi_subscriptions << { event: event_name.to_s, block: block }
          `window.Mochi.on(\#{event_name.to_s}, \#{block})`
        end

        def _cleanup_mochi_subscriptions
          return unless @_mochi_subscriptions
          @_mochi_subscriptions.each do |sub|
            `window.Mochi.off(\#{sub[:event]}, \#{sub[:block]})`
          end
          @_mochi_subscriptions = nil
        end
        RUBY

        # Find insertion point once and insert all methods together
        insertion_point = find_second_last_index(amped_ruby_code, "end")
        if insertion_point && insertion_point > 0
          insertion_point += 3
          methods_code = "\n\n  #{injected_methods.join("\n\n  ")}\n"
          amped_ruby_code = amped_ruby_code[0...insertion_point] + methods_code + amped_ruby_code[insertion_point..-1]
        else
          # Fallback if class structure is simple
          amped_ruby_code += "\n\n#{injected_methods.join("\n\n")}\n"
        end

        web_component = NewComponentGenerator.new.generate(
            mochi_cmp_name = cls_name,
            tag_name = tag_name.not_nil!,
            css,
            html = each_result.html,
            reactables,
            bindings.bindings,
            conditional_result.conditionals,
            each_result.each_blocks
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


end
