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
          return Fetcher.new
        end
        
        def fetch(url, config)
          js_config = config.to_js
          promise = `fetch(#{url}, #{js_config})`
          resp = promise.__await__
          return HttpResponse.new(resp)
        end
      end
      
      class FetchConfig
        attr_reader :method, :headers, :body, :keep_alive
        
        def initialize(method, headers, body, keep_alive)
          @method = method
          @headers = headers
          @body = body
          @keep_alive = keep_alive
        end
        
        def to_s
          return "FetchConfig(method:'#{method}', headers:#{headers}, body:#{body}, keep_alive:#{keep_alive})"
        end
        
        def to_js
          rb_hash = {
            method: method,
            headers: headers.to_n,
            keep_alive: keep_alive
          }
          # only attach the body on POST and HEAD requests
          if (method == "POST" || method == "HEAD")
            rb_hash[:body] = body.to_s
          end
          return rb_hash.to_n
        end
      end
      
      class FetchConfigBuilder
        attr_reader :method, :headers, :body, :keep_alive
        
        def initialize
          @method = "GET"
          @headers = {}
          @body = ""
          @keep_alive = false
        end
        
        def set_method(method)
          @method = method
          return self
        end
        
        def set_headers(headers)
          @headers = headers
          return self
        end
        
        def set_body(body)
          @body = body
          return self
        end
        
        def set_keep_alive(keep_alive)
          @keep_alive = keep_alive
          return self
        end
        
        def build
          return FetchConfig.new(method, headers, body, keep_alive)
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
      
      class Charts
      
        def initialize
        end
        
        def self.setup_environment
            scriptSrc = "https://cdn.jsdelivr.net/npm/echarts@6.0.0/dist/echarts.min.js"
            scriptId = "mc_ec_lib"
            `
            if (document.getElementById(scriptId)) {
                return;
            }

            const script = document.createElement('script');

            script.id = scriptId;
            script.src = scriptSrc;

            document.head.appendChild(script);
            `
            puts "Successfully set up charts environment."
        end
    
        def self.init_on_element_by_query(shadow_root, query)
          return `echarts.init(#{shadow_root}.querySelector(#{query}))`
        end
        
        def self.load_config(chart_el, config)
          option = config.to_js
          `#{chart_el}.setOption(#{option});`
        end
        
      end
      
      class ChartSeries
        def initialize(name, type, data)
          @name = name
          @type = type
          @data = data
        end
      end
      
      class ChartSeriesBuilder
        attr_reader :name, :type, :data
      
        def initialize
          @name = ""
          @type = "bar"
          @data = []
        end
        
        def set_name(name)
          @name = name
          return self
        end
        
        def set_type(type)
          @type = type
          return self
        end
        
        def set_data(data)
          @data = data
          return self
        end
        
        def build
          return ChartSeries.new(name, type, data)
        end
      end
      
      class ChartConfig
        attr_reader :title, :legend, :x_axis, :y_axis, :series
        
        def initialize(title, legend, x_axis, y_axis, series)
          @title = title
          @legend = legend
          @x_axis = x_axis
          @y_axis = y_axis
          @series = series
        end
      
        def to_js
          result = {}
          `
          var option = {
            title: {
              text: #{title}
            },
            tooltip: {},
            legend: {
              data: #{legend}
            },
            xAxis: {},
            yAxis: {},
            series: #{series}
          };
          if (#{x_axis}.length > 0) {
            option.xAxis = { data: #{x_axis} };
          }
          if (#{y_axis}.length > 0) {
            option.yAxis = { data: #{y_axis} };
          }
          
          console.log(option);
          #{result} = option;
          `
        
          return result
        end
        
      end
      
      class ChartConfigBuilder
        attr_reader :title, :legend, :x_axis, :y_axis, :series

        def initialize
          @title = ""
          @legend = []
          @x_axis = []
          @y_axis = []
          @series = []
        end
        
        def set_title(title)
          @title = title
          return self
        end
        
        def set_legend(legend)
          @legend = legend
          return self
        end
        
        def set_x_axis(x_axis)
          @x_axis = x_axis
          return self
        end
        
        def set_y_axis(y_axis)
          @y_axis = y_axis
          return self
        end
        
        def set_series(series)
          @series = series
          return self
        end
        
        def build
          return ChartConfig.new(title, legend, x_axis, y_axis, series)
        end
      end
    RUBY
  end
end