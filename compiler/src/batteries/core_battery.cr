require "file_utils"
require "../generated/mochi_rb"
require "../generated/app_router_rb"
require "../generated/browser_id_rb"
require "../generated/logger_rb"

require "../generated/charts/charts_rb"
require "../generated/charts/chart_series_rb"
require "../generated/charts/chart_config_rb"
require "../generated/charts/chart_config_builder_rb"
require "../generated/charts/chart_series_builder_rb"

require "../generated/fetcher/http_response_rb"
require "../generated/fetcher/fetch_config_builder_rb"
require "../generated/fetcher/fetch_config_rb"
require "../generated/fetcher/fetcher_rb"

class CoreBattery

  def self.generate(ruby_src_dir : String)
    output_dir = "#{ruby_src_dir}/lib"
    if !Dir.exists?(output_dir)
      Dir.mkdir_p(output_dir)
    end

    File.write("#{output_dir}/mochi.rb", self.generate_core_utils)
  end

  def self.generate_core_utils : String
    result = <<-'RUBY'
      # await: true
      require 'json'
      require "await"
    RUBY

    fragments = [
      MochiRbFragment,
      AppRouterRbFragment,
      BrowserIdRbFragment,
      LoggerRbFragment,
      # charts
      ChartsRbFragment,
      ChartSeriesRbFragment,
      ChartConfigBuilderRbFragment,
      ChartConfigRbFragment,
      ChartSeriesBuilderRbFragment,
      # fetcher
      HttpResponseRbFragment,
      FetchConfigBuilderRbFragment,
      FetchConfigRbFragment,
      FetcherRbFragment
    ].map { |fragment_class| fragment_class.get_ruby_code }.join("\n")

    return "#{result}\n#{fragments}"
  end
end
