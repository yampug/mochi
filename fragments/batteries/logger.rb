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
