class ChartSeriesRbFragment
def self.get_ruby_code : String
<<-'RUBY'
class ChartSeries
  def initialize(name, type, data)
    @name = name
    @type = type
    @data = data
  end
end
RUBY
end
end