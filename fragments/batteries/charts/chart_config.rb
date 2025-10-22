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
