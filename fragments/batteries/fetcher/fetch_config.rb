class FetchConfig
  attr_reader :method, :headers, :body, :keep_alive

  def initialize(method, headers, body, keep_alive)
    @method = method
    @headers = headers
    @body = body
    @keep_alive = keep_alive
  end

  def to_s
    return "FetchConfig(method:'#{method}', headers:#{headers}, body:#{body}, keep_alive:#{keep_alive})"
  end

  def to_js
    rb_hash = {
      method: method,
      headers: headers.to_n,
      keep_alive: keep_alive
    }
    # only attach the body on POST and HEAD requests
    if (method == "POST" || method == "HEAD")
      rb_hash[:body] = body.to_s
    end
    return rb_hash.to_n
  end
end
