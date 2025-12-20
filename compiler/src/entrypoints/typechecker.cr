require "colorize"
require "./building/build_main"

class Typechecker

  def typecheck(input_dir : String)
    builder_man = BuilderMan.new(input_dir)
    # steps 2-4
    BuildMain.new.setup(builder_man)

    root_dir = builder_man.ruby_src_dir
    files = Dir.glob(File.join(root_dir, "**", "*.rb"))
    if files.size < 1
      puts "Error: Cannot run typechecks, no ruby files found".colorize(:red)
      exit 1
    end

    puts "Typechecking #{files.size} files..."

    # Initialize Sorbet (generates config and RBI files)
    `cd #{builder_man.ruby_src_dir} && bundle install > /dev/null 2>&1`
    #`cd #{builder_man.ruby_src_dir} && export SRB_YES=1 && srb init > /dev/null 2>&1`

    session = Sorbet::Session.new(
      root_dir: root_dir,
      multi_threaded: false
    )

    # Send all files in batch so Sorbet sees the entire project at once
    # Like this Sorbet will resolve cross-file constants correctly because
    # it has all definitions before resolving.
    result = session.typecheck_files(files)
    if result.success?
      puts "✓ No type errors found!".colorize(:green)
    else
      puts "✗ Found errors:".colorize(:red)
      i = 1
      result.errors.each do |error|
        trimmed_file_path = error.file[builder_man.ruby_src_dir.size, error.file.size]
        file_path_line_col = "#{trimmed_file_path}@#{error.line}:#{error.column}"
        puts "  [Error ##{i}]  #{error.message.colorize(:red)} [#{file_path_line_col.colorize(:yellow)}]"
        i += 1
      end
    end

    session.close
  end
end
