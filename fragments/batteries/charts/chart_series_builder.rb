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
