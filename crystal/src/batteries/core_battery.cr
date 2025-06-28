require "file_utils"

class CoreBattery

  def self.generate(ruby_src_dir : String)
    output_dir = "#{ruby_src_dir}/lib"
    if !Dir.exists?(output_dir)
      Dir.mkdir_p(output_dir)
    end

    File.write("#{output_dir}/../mochi.rb", self.generate_core_utils)
  end
  
  def self.generate_core_utils : String
    <<-'RUBY'
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
        end
      end
    RUBY
  end
end