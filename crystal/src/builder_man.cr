require "file_utils"

class BuilderMan

  @input_dir : String
  @build_id : String

  def initialize(input_dir : String)
    @input_dir = input_dir
    @build_id = generate_build_id
    # create mochi dir
    create_mochi_dir_if_missing

    # create the build dir inside the mochi dir
    build_dir_path = build_dir
    if Dir.exists?(build_dir_path)
      FileUtils.rm_rf(build_dir_path)
      Dir.mkdir(build_dir_path)
    else
      Dir.mkdir_p(build_dir_path)
    end
  end

  def create_mochi_dir_if_missing
    build_dir = "/tmp/mochi"
    if Dir.exists?(build_dir)
    else
      Dir.mkdir_p(build_dir)
    end
  end

  def build_dir : String
    "/tmp/mochi/#{@build_id}"
  end

  def ruby_src_dir : String
    "#{build_dir}/src"
  end

  def build_id : String
    @build_id
  end

  def copy_ruby_code_base
    source_dir = "#{@input_dir}/*"
    destination_dir = ruby_src_dir

    `mkdir #{destination_dir} && cp -r #{source_dir} #{destination_dir}`

    # copy batteries
    bat_source_dir = "#{@input_dir}/../batteries/*"
    `cp -r #{bat_source_dir} #{destination_dir}/lib`
  end
end
