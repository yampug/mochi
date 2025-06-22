class OpalRuntimeGenerator

  def initilize
  end
  
  def generate(build_dir : String)
    output_file = "#{build_dir}/opal-runtime.js"
    # TODO define list of gems to include with -g text AND -r text
    #`opal -g promise -g opal-browser -g native -r opal-browser -r native -r promise  -q opal-browser -p promise -p opal-browser -p browser/setup/full -c -e '#' -E > #{output_file}`
    `opal -c -q opal-browser -p native -p promise -p opal-browser -p browser/setup/full -e '#' -E > #{output_file}`
  end
  
end