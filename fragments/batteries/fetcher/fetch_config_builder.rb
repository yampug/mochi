class FetchConfigBuilder
  attr_reader :method, :headers, :body, :keep_alive

  def initialize
    @method = "GET"
    @headers = {}
    @body = ""
    @keep_alive = false
  end

  def set_method(method)
    @method = method
    return self
  end

  def set_headers(headers)
    @headers = headers
    return self
  end

  def set_body(body)
    @body = body
    return self
  end

  def set_keep_alive(keep_alive)
    @keep_alive = keep_alive
    return self
  end

  def build
    return FetchConfig.new(method, headers, body, keep_alive)
  end

end
