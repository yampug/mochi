class ChartConfigBuilderRbFragment
  def self.get_ruby_code : String
    <<-'RUBY'
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
