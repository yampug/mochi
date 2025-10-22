require "file_utils"
require "../generated/mochi_rb"
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



      class Log

        def self.inner_log(cls, msg, level)
          caller_info = get_caller_info
          date_time = get_formatted_date_time
          log_msg = "%c#{msg} \n%c[#{cls.class.name}, #{caller_info}, #{date_time}]"
          if level == "object" || level == "pretty"
            type_of_info = `typeof #{msg}`
            log_msg = "%cType: #{type_of_info} \n%c[#{cls.class.name}, #{caller_info}, #{date_time}]"
          end

          color_a = "color: #bbb; padding: 2px 6px; border-radius: 3px;"
          color_b = "color: inherit; background-color: inherit;"

          if level == "warn"
            `console.warn(#{log_msg}, #{color_b}, #{color_a})`
          else
            if level == "error"
              `console.error(#{log_msg}, #{color_b}, #{color_a})`
            else
              if level == "trace"
                `console.trace(#{log_msg}, #{color_b}, #{color_a})`
              else
                if level == "object" || level == "pretty"
                  `console.log(#{log_msg}, #{color_b}, #{color_a})`
                  if level == "pretty"
                    `console.log(JSON.stringify(#{msg}, 0, 2))`
                  else
                    `console.log(#{msg})`
                  end
                else
                  # info
                  `console.log(#{log_msg}, #{color_b}, #{color_a})`
                end
              end
            end
          end
        end

        def self.info(cls, msg)
          self.inner_log(cls, msg, "info")
        end

        def self.warn(cls, msg)
          self.inner_log(cls, msg, "warn")
        end

        def self.error(cls, msg)
          self.inner_log(cls, msg, "error")
        end

        def self.trace(cls, msg)
          self.inner_log(cls, msg, "trace")
        end

        def self.object(cls, obj)
          self.inner_log(cls, obj, "object")
        end

        def self.pretty(cls, obj)
          self.inner_log(cls, obj, "pretty")
        end

        def self.time_start(cls, label)
          `console.time(#{label});`
        end

        def self.time_end(cls, label)
          self.inner_log(cls, label, "info")
          `console.timeEnd(#{label});`
        end

        def self.get_caller_info
          info = ""
          `
          const err = new Error();

          try {
            const callerLine = err.stack.split('\n')[4].trim();
            const lastParen = callerLine.lastIndexOf(')');
            const firstParen = callerLine.lastIndexOf('(', lastParen);
            const location = callerLine.substring(firstParen + 1, lastParen);

            info = location.split('/').pop();

          } catch (e) {
            // ignore
          }
          `
          return info
        end

        def self.get_formatted_date_time
          date_time = ""
          `
            const months = [
              'jan', 'feb', 'mar', 'apr', 'may', 'jun',
              'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
            ];

            const now = new Date();

            const month = months[now.getMonth()];
            const day = now.getDate();
            const year = now.getFullYear() - 2000;

            const hours = String(now.getHours()).padStart(2, '0');
            const minutes = String(now.getMinutes()).padStart(2, '0');
            const seconds = String(now.getSeconds()).padStart(2, '0');

            #{date_time} = hours + ":" + minutes + ":" + seconds + " " + month + day + "-" + year;
          `
          return date_time
        end

      end

      class BrowserIdentifier

        def self.is_chrome_based(vendor)
          return vendor === "Google Inc."
        end

        def self.is_safari(vendor)
          return vendor === "Apple Computer, Inc."
        end

        def self.is_orion(user_agent_data)
          if `#{user_agent_data}`
            return `#{user_agent_data}.brands[0].brand === "Orion"`
          end
          return false
        end

        def self.is_firefox(user_agent)
          return user_agent.include?("Firefox")
        end

        def self.identify
          user_agent = `window.clientInformation.userAgent`
          vendor = `window.clientInformation.vendor`
          user_agent_data = `window.clientInformation.userAgentData`

          if is_chrome_based(vendor)
            return "chrome_based"
          end

          if is_orion(user_agent_data)
            return "orion"
          end

          if is_safari(vendor)
            return "safari"
          end

          if is_firefox(user_agent)
            return "firefox"
          end

          return "unknown"
        end
      end

      class AppRouter
        def initialize(&block)
          @routes = []
          instance_eval(&block) if block_given?
        end

        def on(path_pattern, &handler)
          names, regex = compile_path(path_pattern)
          @routes << { names: names, regex: regex, handler: handler }
        end

        def not_found(&handler)
          @not_found_handler = handler
        end

        def compile_path(path_pattern)
          names = []
          # Turn /users/:id into a regex
          regex_string = path_pattern.gsub(/:\w+/) do |match|
            # Store the name of the parameter (e.g., "id")
            names << match.tr(':', '')
            # Replace it with a capture group
            '([^\/]+)'
          end

          # Ensure it matches the full path
          [names, Regexp.new("^#{regex_string}$")]
        end

        def resolve
          path = `window.location.pathname`
          query_params = `window.location.search`
          resolve_manual(path, query_params)
        end

        def resolve_manual(path, query_params)
          @routes.each do |route|
            match_data = path.match(route[:regex])

            # If the regex matches the path...
            if match_data
              # Create the params hash
              # e.g., ["id"] and ["123"] => {"id" => "123"}
              params = Hash[route[:names].zip(match_data.captures)]

              # Call the stored block with the params
              return route[:handler].call(params)
            end
          end

          # If no route was found, call the not_found handler
          @not_found_handler.call if @not_found_handler
        end
      end
    RUBY

    fragments = [
      MochiRbFragment,
      ChartsRbFragment,
      ChartSeriesRbFragment,
      ChartConfigBuilderRbFragment
    ].map { |fragment_class| fragment_class.get_ruby_code }.join("\n")

    return "#{result}\n#{fragments}"
  end
end
