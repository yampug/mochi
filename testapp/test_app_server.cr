require "http/server"

def get(wanted_uri : String, context : HTTP::Server::Context) : Bool
  return context.request.method == "GET" && context.request.uri.path == wanted_uri
end

def reply_with_file(context : HTTP::Server::Context, path : String, content_type : String)
    content = File.read(path)
    context.response.content_type = content_type
    context.response.print content
end

def reply_with_html_file(context : HTTP::Server::Context, path : String)
    reply_with_file(context, path, "text/html")
end

def reply_with_js_file(context : HTTP::Server::Context, path : String)
    reply_with_file(context, path, "application/javascript")
end

def reply_with_png_file(context : HTTP::Server::Context, path : String)
    reply_with_file(context, path, "image/png")
end


server = HTTP::Server.new do |context|

  method = context.request.method
  uri = context.request.uri

  puts "#{method} '#{uri}'"

  replied = false
  if get("/", context) || get("/about", context) || get("/contact", context)
    reply_with_html_file(context, "./devground/public/basic_counters.html")
    replied = true
  end

  if get("/opal-runtime.js", context)
    reply_with_js_file(context, "./devground/public/opal-runtime.js")
    replied = true
  end

  if get("/bundle.js", context)
    reply_with_js_file(context, "./devground/public/bundle.js")
    replied = true
  end

  if get("/mochi.png", context)
    reply_with_png_file(context, "./devground/public/mochi.png")
    replied = true
  end

  if !replied
    context.response.content_type = "text/plain"
    context.response.print "Error: No handler fo #{method} #{uri}"
  end

end

address = server.bind_tcp 8777
puts "Mochi Internal Test Server listening on http://#{address}"
server.listen
