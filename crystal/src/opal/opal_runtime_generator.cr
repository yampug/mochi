class OpalRuntimeGenerator

  def initilize
  end
  
  def generate_old(output_dir : String, tmp_dir : String)
    output_file = "#{tmp_dir}/opal-runtime.js"
    rb_code = ""
    rb_code += "require 'opal'\n"
    rb_code += "require 'opal-browser'\n"
    rb_code += "opal_runtime_javascript = Opal::Builder.build('opal').to_s\n"
    rb_code += "opal_browser_runtime_javascript = Opal::Builder.build('opal-browser').to_s\n"
    rb_code += "runtime_filename = '#{output_file}'\n"
    rb_code += "File.open(runtime_filename, 'w') do |file|\n"
    rb_code += "  file.write(opal_runtime_javascript + '\n' + opal_browser_runtime_javascript)\n"
    rb_code += "end\n"
    rb_code += "puts \"Opal runtime has been successfully compiled to #{output_file}\"\n"
    
    script_file = "#{tmp_dir}/mochi_gen_opal_runtime.rb"
    File.write(script_file, rb_code)
    
    `ruby #{script_file}`
    
    
  end
  
  def generate(output_dir : String, tmp_dir : String)
    output_file = "#{tmp_dir}/opal-runtime.js"
    # TODO define list of gems to include with -g text AND -r text
    #`opal -g promise -g opal-browser -g native -r opal-browser -r native -r promise  -q opal-browser -p promise -p opal-browser -p browser/setup/full -c -e '#' -E > #{output_file}`
    `opal -c -q opal-browser -p native -p promise -p opal-browser -p browser/setup/full -e '#' -E > #{output_file}`
  end
  
end