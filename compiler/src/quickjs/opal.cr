require "./runtime"

module QuickJS
  module Opal
    class Compiler
      def initialize
        @js = QuickJS::Runtime.new
        # at least 64MB
        @js.set_max_stack_size((64 * 1024 * 1024).to_u64)
        load_opal
      end

      def finalize
        @js.finalize
      end

      def compile(ruby_code : String, filename : String? = nil, requirable : Bool = false) : String
        @js["__temp_ruby_code__"] = ruby_code

        opts_str = String.build do |s|
          s << "{"
          s << "file: '#{filename}'," if filename
          s << "requirable: true," if requirable
          s << "method_missing: false,"
          s << "arity_check: false,"
          s << "frozen_string_literal: true,"
          s << "}"
        end

        result = @js.eval("Opal.compile(__temp_ruby_code__, #{opts_str})")
        result.to_s
      end

      def eval(ruby_code : String) : QuickJS::Value
        js_code = compile(ruby_code)
        @js.eval(js_code)
      end

      private def load_opal
        exe_dir = File.dirname(Process.executable_path || "")
        candidates = [
          "fragments/vendor/opal",
          "../fragments/vendor/opal",
          File.join(exe_dir, "../fragments/vendor/opal"),
          File.join(exe_dir, "fragments/vendor/opal"),
        ]
        base_path = candidates.find { |p| File.exists?(File.join(p, "opal.js")) }

        raise "Opal vendor files not found at #{candidates.join(" or ")}" unless base_path

        opal_path = File.join(base_path, "opal.js")
        parser_path = File.join(base_path, "opal-parser.js")

        unless File.exists?(opal_path) && File.exists?(parser_path)
           raise "Opal vendor files not found at #{opal_path} or #{parser_path}"
        end

        @js.eval_file(opal_path)

        unless @js["Opal"].object?
            raise "Opal failed to load"
        end

        @js.eval_file(parser_path)
        @js.eval("Opal.load('opal-parser')")

        # Opal is loaded?
        unless @js["Opal"].object?
            raise "Opal failed to load"
        end
      end
    end
  end
end
