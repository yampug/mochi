class JsLoggerGenerator

  
  def initialize
  end
  
  def self.generate : String
    int_logs_enabled = ENV["MO_INT_LOGS"] == "true"
    int_logs_level = ENV["MO_INT_LOGS_LEVEL"]

    puts "> Internal Logs enabled: #{int_logs_enabled}"

    is_debug_or_above = int_logs_level == "DEBUG"
    is_info_or_above = is_debug_or_above || int_logs_level == "INFO"
    is_warn_or_above = is_info_or_above || int_logs_level == "WARN"
    is_error_or_above = is_warn_or_above || int_logs_level == "ERROR"


    color_a = "color: #bbb; padding: 2px 6px; border-radius: 3px;"
    color_b = "color: inherit; background-color: inherit;"

    js_code = <<-TEXT
  
        class il {
            static formatLog(msg, suffix) {
                return "%c" + msg + "__nl__%c internal_log:" + suffix
            }

            static debug(msg) {
                if (#{int_logs_enabled} && #{is_debug_or_above}) {
                    console.debug(il.formatLog(msg, "debug"), "#{color_b}", "#{color_a}");
                }
            }

            static info(msg) {
                if (#{int_logs_enabled} && #{is_info_or_above}) {
                    console.log(il.formatLog(msg, "info"), "#{color_b}", "#{color_a}");
                }
            }

            static warn(msg) {
                if (#{int_logs_enabled} && #{is_warn_or_above}) {
                    console.warn(il.formatLog(msg, "warn"), "#{color_b}", "#{color_a}");
                }
            }
            
            static error(msg) {
                if (#{int_logs_enabled} && #{is_error_or_above}) {
                    console.error(il.formatLog(msg, "error"), "#{color_b}", "#{color_a}");
                }
            }
        }
    TEXT
    return js_code
  end
end