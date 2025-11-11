class OpalRuntimeGenerator

  def initilize
  end
  
  def get_runtime_file_path(build_dir) : String
    return "#{build_dir}/opal-runtime.js"
  end
  
  def generate(build_dir : String)
    output_file = get_runtime_file_path(build_dir)
    
    `opal -c -q opal-browser -p native -p promise -p opal-browser -p browser/setup/full -s sorbet -s sorbet-runtime -e '#' -E > #{get_runtime_file_path(build_dir)}`    
  end
  
end