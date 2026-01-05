require "file_utils"

class BuilderMan

  @input_dir : String
  @build_id : String

  def initialize(input_dir : String)
    @input_dir = input_dir
    @build_id = generate_build_id
    # create mochi dir
    create_mochi_dir_if_missing

    opal_rt_file = "runtime.js"
    entries_to_delete = Dir.entries(build_dir).reject do |entry|
      entry == "." || entry == ".." || entry == opal_rt_file
    end

    paths_to_delete = entries_to_delete.map { |entry| File.join(build_dir, entry) }

    # create the build dir inside the mochi dir
    build_dir_path = build_dir
    if Dir.exists?(build_dir_path)
      unless paths_to_delete.empty?
        FileUtils.rm_rf(paths_to_delete)
      else
        puts "Nothing to delete."
      end
      Dir.mkdir_p(build_dir_path)
    else
      Dir.mkdir_p(build_dir_path)
    end
  end

  def create_mochi_dir_if_missing
    build_dir = "#{Dir.current}/build"
    if Dir.exists?(build_dir)
    else
      Dir.mkdir_p(build_dir)
    end
  end

  def build_dir : String
    "#{Dir.current}/build"
  end

  def ruby_src_dir : String
    "#{build_dir}/src"
  end

  def pre_tp_dir : String
    "#{build_dir}/pre_tp"
  end

  def build_id : String
    @build_id
  end

  def copy_ruby_code_to_pre_tp
    source_dir = "#{@input_dir}/*"
    destination_dir = pre_tp_dir

    `mkdir -p #{destination_dir} && cp -r #{source_dir} #{destination_dir}`
  end

  def copy_ruby_code_base
    source_dir = "#{pre_tp_dir}/*"
    destination_dir = ruby_src_dir

    `mkdir -p #{destination_dir} && cp -r #{source_dir} #{destination_dir}`
  end
end
