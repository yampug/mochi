require "file_utils"

class CoreBattery

  def self.generate(ruby_src_dir : String)
    output_dir = "#{ruby_src_dir}/lib"
    if !Dir.exists?(output_dir)
      Dir.mkdir_p(output_dir)
    end

    File.write("#{output_dir}/mochi.rb", self.generate_core_utils)
  end
  
  def self.generate_core_utils : String
    <<-'RUBY'
      # await: true
      require 'json'
      require "await"

      class Mochi
      
        def self.interval(proc, time_ms)
          `setInterval(#{proc}, #{time_ms})`
        end
      
        def self.timeout(proc, time_ms)
          `setTimeout(#{proc}, #{time_ms})`
        end
      
        def self.clear_interval(interval_id)
          `clearInterval(#{interval_id});`
        end
      end
      
      class Fetcher
      
        def self.create
          puts "created fetcher"
          return Fetcher.new
        end
        
        def get(url)
          puts "fetching #{url}"
          promise = `fetch(#{url})`
          resp = promise.await
          return resp
        end
      end
      
      # Unpacks the JS Object into a native Ruby Object for ease of access
      class HttpResponse
        attr_reader :raw
        
        def initialize(raw)
          @raw = `raw`
        end
        
        def url # String
          `#{raw}.url`
        end
        
        def type # String
          `#{raw}.type`
        end
        
        def ok # Boolean
          `#{raw}.ok`
        end
        
        def redirected # Boolean
          `#{raw}.redirected`
        end
        
        def status # Number
          `#{raw}.status`
        end
        
        def status_text # String
          `#{raw}.statusText`
        end
        
        def body_used # Boolean
          `#{raw}.bodyUsed`
        end
        
        def body_as_text # String
          return `#{raw}.text()`
        end
        
        def body_as_hash # Hash
          json = `#{raw}.text()`.__await__
          return JSON.parse(json)
        end
        
        def headers # Hash
          js_map = `new Map(#{raw}.headers)`
          native_map = Native(js_map)
          result = native_map.to_h
          return result
        end
        
        def to_s
          return "HttpResponse(url:#{url}, type:#{type}, ok:#{ok}, redirected:#{redirected}, status:#{status}, status_text:#{status_text}, body_used:#{body_used}, headers:#{headers})"
        end
      end
    RUBY
  end
end