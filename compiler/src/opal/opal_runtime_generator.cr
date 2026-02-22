require "file_utils"

class OpalRuntimeGenerator

  def initilize
  end

  def get_runtime_file_path(build_dir) : String
    return "#{build_dir}/runtime.js"
  end

  def generate(build_dir : String)
    output_file = get_runtime_file_path(build_dir)

    # Base Opal runtime
    base_runtime = File.read("../fragments/vendor/runtime.js")
    
    # New runtime components
    mochi_comp = File.read("src/js/runtime/mochi_component.js")
    signal_rt = File.read("src/js/runtime/signal.js")
    
    File.write(output_file, base_runtime + "\n" + signal_rt + "\n" + mochi_comp)
  end

end
