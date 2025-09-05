# typed: true
class ChartDemo

  @tag_name = "chart-demo"
  @pfcount

  def initialize
    @pfcount = 0
  end

  def reactables
    []
  end

  def html
    %Q{
      <div id="main" style="width: 600px;height:400px;">
      </div>
    }
  end

  def css
    %Q{
      
    }
  end

  def mounted(shadow_root)
    puts "ChartDemo mounted"
    `console.log(shadow_root)`
    
    interval_id = Mochi.interval(proc do
      Charts.setup_environment
  
      Mochi.timeout(proc do
        Mochi.clear_interval(interval_id)
        
        chart_el = Charts.init_on_element_by_query(shadow_root, "#main")
        config = ChartConfigBuilder.new()
          .set_title("My Own Chart Title")
          .set_legend(["sales"])
          .set_x_axis(["Shirts", "Cardigans", "Chiffons", "Pants", "Heels", "Socks"])
          .set_y_axis([])
          .set_series(
            [
              ChartSeriesBuilder.new()
                .set_name("sales")
                .set_type("bar")
                .set_data([5, 20, 36, 10, 10, 20])
                .build()
            ]
          )
          .build()
        
        Charts.load_config(chart_el, config)
        
        puts "done"
      end, 2000)
    end, 1000)
    
  end

  def unmounted
    puts "ChartDemo unmounted"
  end
end
