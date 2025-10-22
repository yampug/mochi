class Charts

  def initialize
  end

  def self.setup_environment
    scriptSrc = "https://cdn.jsdelivr.net/npm/echarts@6.0.0/dist/echarts.min.js"
    scriptId = "mc_ec_lib"
    `
            if (document.getElementById(scriptId)) {
                return;
            }

            const script = document.createElement('script');

            script.id = scriptId;
            script.src = scriptSrc;

            document.head.appendChild(script);
            `
    puts "Successfully set up charts environment."
  end

  def self.init_on_element_by_query(shadow_root, query)
    return `echarts.init(#{shadow_root}.querySelector(#{query}))`
  end

  def self.load_config(chart_el, config)
    option = config.to_js
    `#{chart_el}.setOption(#{option});`
  end

end
