require "./opal"
require "./../caching/cache"
require "digest/md5"

module QuickJS
  module Opal
    class Builder
      def initialize(include_runtime : Bool = true)
        @compiler = Compiler.new
        @parts = [] of String

        add_vendor_file("opal.js") if include_runtime
      end

      def finalize
        @compiler.finalize
      end

      def add_raw_js(content : String)
        @parts << content
      end

      def add_stdlib(name : String)
        filename = name.ends_with?(".js") ? name : "#{name}.js"
        root = resolve_vendor_root
        path = "#{root}/opal/#{filename}"

        if File.exists?(path)
          @parts << File.read(path)
        else
          puts "Warning: Opal stdlib #{name} not found at #{path}"
        end
      end

      def resolve_vendor_root
         ["fragments/vendor", "../fragments/vendor"].find { |p| Dir.exists?(File.join(p, "opal")) } || "fragments/vendor"
      end

      def add_vendor_file(filename : String)
        root = resolve_vendor_root
        path = "#{root}/opal/#{filename}"
        if File.exists?(path)
          @parts << File.read(path)
        else
          raise "Vendor file #{filename} not found at #{path}"
        end
      end

      # adds dir to load path
      def add_directory(path : String)
        Dir.glob(Path[path, "**", "*.rb"].to_s) do |file|
          if File.file?(file)
             content = File.read(file)
             relative_path = Path[file].relative_to(path).to_s
             compile(content, relative_path)
          end
        end
      end

      def compile_with_cache(code : String, path : String, cache : Cache, requirable : Bool = true)
        compiled = ""
        cache_key = Digest::MD5.hexdigest("#{path}::#{code}")
        if cache.has(cache_key)
          compiled = cache.get(cache_key)
        else
          compiled = @compiler.compile(code, path, requirable: requirable)
          cache.put(cache_key, compiled)
        end

        @parts << compiled
      end

      def compile(code : String, path : String, requirable : Bool = true)
        compiled = @compiler.compile(code, path, requirable: requirable)
        @parts << compiled
      end

      def build(entry_point : String? = nil) : String
        final = @parts.join("\n")
        if entry_point
           mod_name = entry_point.chomp(".rb")
           final += "\nOpal.require('#{mod_name}');"
        end
        final
      end
    end
  end
end
