require "file_utils"

class OpalRuntimeGenerator

  def initilize
  end

  def get_runtime_file_path(build_dir) : String
    return "#{build_dir}/runtime.js"
  end

  def generate(build_dir : String)
    output_file = get_runtime_file_path(build_dir)

    # TODO make path different in production
    FileUtils.cp("../fragments/vendor/runtime.js", output_file)
    #Old code:`opal -c -q opal-browser -p native -p promise -p opal-browser -p browser/setup/full -s sorbet -s sorbet-runtime -e '#' -E > #{get_runtime_file_path(build_dir)}`
  end

end
