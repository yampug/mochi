require "process"

class ScriptEngine

    def eval(script : String) : String
        puts "Executing Ruby script:\n#{script}"

        escaped_script = script.gsub("\\", "\\\\").gsub("'", "\\'")
        ruby_script_arg = "puts eval('#{escaped_script}')"

        output_io = IO::Memory.new
        error_io = IO::Memory.new

        result = Process.run(
            command: "ruby",
            args: ["-e", ruby_script_arg],
            output: output_io,
            error: error_io
        )

        stdout_str = output_io.to_s
        stderr_str = error_io.to_s

        if result.success?
            return stdout_str.chomp
        else
            raise "Ruby execution failed with exit code #{result.exit_code}:\n#{stderr_str}"
        end
    end

end