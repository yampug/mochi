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


# REGISTRY
items = []
items.push(Item.new("MochiRbFragment", "./fragments/batteries/mochi.rb", "/", "mochi_rb.cr"))
items.push(Item.new("ChartsRbFragment", "./fragments/batteries/charts/charts.rb", "/charts", "charts_rb.cr"))
items.push(Item.new("ChartSeriesRbFragment", "./fragments/batteries/charts/chart_series.rb", "/charts", "chart_series_rb.cr"))



gen_target_path = "./crystal/src/generated"
FileUtils.rm_rf(gen_target_path)

items.each { |item|
  begin
    source_content = File.read(item.src_path).strip
    full_target_path = "#{gen_target_path}/#{item.target_path}"
    full_target_path_w_file = "#{full_target_path}/#{item.target_file_name}"
    FileUtils.mkdir_p(full_target_path)

    content = "class #{item.cls_name}\ndef self.get_ruby_code : String\n<<-'RUBY'\n#{source_content}\nRUBY\nend\nend"

    FileUtils.mkdir_p(File.dirname(full_target_path_w_file))
    File.write(full_target_path_w_file, content)

    puts "Generated '#{item.cls_name}' at '#{full_target_path_w_file}'."

  rescue Errno::ENOENT => e
    puts "Error: #{e.message}. Please check your file paths."
  rescue => e
    puts "An unexpected error occurred: #{e.message}"
  end
}

