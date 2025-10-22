require "file_utils"
require "../generated/mochi_rb"
require "../generated/app_router_rb"
require "../generated/browser_id_rb"
require "../generated/logger_rb"
require "../generated/charts/charts_rb"
require "../generated/charts/chart_series_rb"
require "../generated/charts/chart_config_builder_rb"

class CoreBattery

  def self.generate(ruby_src_dir : String)
    output_dir = "#{ruby_src_dir}/lib"
    if !Dir.exists?(output_dir)
      Dir.mkdir_p(output_dir)
    end

    File.write("#{output_dir}/mochi.rb", self.generate_core_utils)
  end

  def self.generate_core_utils : String
    result = <<-'RUBY'
      # await: true
      require 'json'
      require "await"

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

    RUBY

    fragments = [
      MochiRbFragment,
      AppRouterRbFragment,
      BrowserIdRbFragment,
      LoggerRbFragment,
      ChartsRbFragment,
      ChartSeriesRbFragment,
      ChartConfigBuilderRbFragment
    ].map { |fragment_class| fragment_class.get_ruby_code }.join("\n")

    return "#{result}\n#{fragments}"
  end
end
