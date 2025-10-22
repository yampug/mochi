class Fetcher

  def self.create
    return Fetcher.new
  end

  def fetch(url, config)
    js_config = config.to_js
    promise = `fetch(#{url}, #{js_config})`
    resp = promise.__await__
    return HttpResponse.new(resp)
  end
end
