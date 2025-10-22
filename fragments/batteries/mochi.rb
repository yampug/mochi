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

  def self.window()
    return `window`
  end

  def self.document()
    return `document`
  end

  def self.get_attr(component, name)
    `#{component}.element.getAttribute(#{name})`
  end
end
