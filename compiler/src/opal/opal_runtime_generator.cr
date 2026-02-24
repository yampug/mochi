require "file_utils"

class OpalRuntimeGenerator

  def initilize
  end

  def get_runtime_file_path(build_dir) : String
    return "#{build_dir}/runtime.js"
  end

  def resolve_path(relative_to_exe : String, fallbacks : Array(String)) : String
    exe_dir = File.dirname(Process.executable_path || "")
    all = [File.join(exe_dir, relative_to_exe)] + fallbacks
    all.find { |p| File.exists?(p) } || all.first
  end

  def generate(build_dir : String)
    output_file = get_runtime_file_path(build_dir)

    # Base Opal runtime
    base_runtime = File.read(resolve_path("../fragments/vendor/runtime.js", ["../fragments/vendor/runtime.js"]))

    # New runtime components
    mochi_comp = File.read(resolve_path("src/js/runtime/mochi_component.js", ["src/js/runtime/mochi_component.js"]))
    signal_rt = File.read(resolve_path("src/js/runtime/signal.js", ["src/js/runtime/signal.js"]))
    
    File.write(output_file, base_runtime + "\n" + signal_rt + "\n" + mochi_comp)
  end

end
