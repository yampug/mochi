class Typechecker

  def typecheck()
    puts "Standalone typecheck block"
    session = Sorbet::Session.new(
      root_dir: "./devground/components/lib",
      multi_threaded: false
    )

    # Find all Ruby files in the source directory
    files = Dir.glob(File.join("./devground/components/lib", "**", "*.rb"))
    puts "found #{files.size} files: #{files}"
    result = session.typecheck_files(files)

    puts result
    if result.success?
      puts "✓ No type errors found!"
    else
      puts "✗ Found #{result.errors.size} errors:"
      result.errors.each do |error|
        puts "  #{error}"
      end
    end

    session.close
  end
end
