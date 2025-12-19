class Compiler
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
      reactables = RubyUnderstander.extract_raw_string_from_def_body(methods["reactables"].body, "reactables")
      # puts "reactables:'#{reactables}'"

      reactables_arr = js_to_cr_array(reactables)
      reactables_arr.each do |item|
        # puts "Item: #{item}"
      end

      # Process conditionals before binding extraction
      conditional_result = ConditionalProcessor.process(html)

      # Inject conditional methods into Ruby code
      amped_ruby_code = ConditionalMethodGenerator.inject_methods_into_class(
      amped_ruby_code,
      cls_name,
      conditional_result.conditionals
      )

      # Process each blocks
      each_result = EachProcessor.process(conditional_result.html)

      # Inject each methods into Ruby code
      amped_ruby_code = EachMethodGenerator.inject_methods_into_class(
      amped_ruby_code,
      cls_name,
      each_result.each_blocks
      )

      bindings = BindExtractor.extract(each_result.html)
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
