require "colorize"

class Typechecker

  def typecheck(path : String)
    files = Dir.glob(File.join(path, "**", "*.rb"))
    if files.size < 1
      puts "Error: Cannot run typechecks, no ruby files found".colorize(:red)
      exit 1
    end

    puts "Typchecking #{files.size} files..."
    session = Sorbet::Session.new(
      root_dir: path,
      multi_threaded: false
    )

    result = session.typecheck_files(files)
    if result.success?
      puts "✓ No type errors found!".colorize(:green)
    else
      puts "✗ Found #{result.errors.size} errors:".colorize(:red)
      i = 1
      result.errors.each do |error|
        puts "  [Error ##{i}]  #{error.colorize(:red)}"
        i += 1
      end
    end

    session.close
  end
end
