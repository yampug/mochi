require 'fileutils'

class Item
  attr_reader :cls_name, :src_path, :target_path, :target_file_name

  def initialize(cls_name, src_path, target_path, target_file_name)
    @cls_name = cls_name
    @src_path = src_path
    @target_path = target_path
    @target_file_name = target_file_name
  end
end

dir_batteries = "./fragments/batteries"
dir_builtins = "./fragments/builtins"
dir_charts = "#{dir_batteries}/charts"
dir_fetcher = "#{dir_batteries}/fetcher"
dir_router = "#{dir_builtins}/router"

# target dirs
td_root = "/"
td_charts = "/charts"
td_fetcher = "/fetcher"
td_builtins = "/builtins"
td_router = "/builtins/router"

# REGISTRY
# -- BATTERIES
items = []
items.push(Item.new("Mochi", "#{dir_batteries}/mochi.rb", td_root, "mochi_rb.cr"))
items.push(Item.new("AppRouter", "#{dir_batteries}/app_router.rb", td_root, "app_router_rb.cr"))
items.push(Item.new("BrowserId", "#{dir_batteries}/browser_id.rb", td_root, "browser_id_rb.cr"))
items.push(Item.new("Logger", "#{dir_batteries}/logger.rb", td_root, "logger_rb.cr"))

# ----- charts
items.push(Item.new("Charts", "#{dir_charts}/charts.rb", td_charts, "charts_rb.cr"))
items.push(Item.new("ChartSeries", "#{dir_charts}/chart_series.rb", td_charts, "chart_series_rb.cr"))
items.push(Item.new("ChartConfigBuilder", "#{dir_charts}/chart_config_builder.rb", td_charts, "chart_config_builder_rb.cr"))
items.push(Item.new("ChartConfig", "#{dir_charts}/chart_config.rb", td_charts, "chart_config_rb.cr"))
items.push(Item.new("ChartSeriesBuilder", "#{dir_charts}/chart_series_builder.rb", td_charts, "chart_series_builder_rb.cr"))

# ----- fetcher
items.push(Item.new("HttpResponse", "#{dir_fetcher}/http_response.rb", td_fetcher, "http_response_rb.cr"))
items.push(Item.new("FetchConfigBuilder", "#{dir_fetcher}/fetch_config_builder.rb", td_fetcher, "fetch_config_builder_rb.cr"))
items.push(Item.new("FetchConfig", "#{dir_fetcher}/fetch_config.rb", td_fetcher, "fetch_config_rb.cr"))
items.push(Item.new("Fetcher", "#{dir_fetcher}/fetcher.rb", td_fetcher, "fetcher_rb.cr"))

# -- BUILT_IN (BI) Components
items.push(Item.new("FeatherIconBI", "#{dir_builtins}/feather_icon.rb", td_builtins, "feather_icon_rb.cr"))
items.push(Item.new("RouteBI", "#{dir_router}/route.rb", td_router, "route_rb.cr"))
items.push(Item.new("MochiRouterBI", "#{dir_router}/mochi_router.rb", td_router, "mochi_router_rb.cr"))

gen_target_path = "./crystal/src/generated"
FileUtils.rm_rf(gen_target_path)

items.each { |item|
  begin
    source_content = File.read(item.src_path).strip
    full_target_path = "#{gen_target_path}/#{item.target_path}"
    full_target_path_w_file = "#{full_target_path}/#{item.target_file_name}"
    FileUtils.mkdir_p(full_target_path)

    content = "class #{item.cls_name}RbFragment\ndef self.get_ruby_code : String\n<<-'RUBY'\n#{source_content}\nRUBY\nend\nend"

    FileUtils.mkdir_p(File.dirname(full_target_path_w_file))
    File.write(full_target_path_w_file, content)

    puts "Generated '#{item.cls_name}' at '#{full_target_path_w_file}'."

  rescue Errno::ENOENT => e
    puts "Error: #{e.message}. Please check your file paths."
  rescue => e
    puts "An unexpected error occurred: #{e.message}"
  end
}

