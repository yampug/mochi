require "http/server"

class DevServer
  def get(wanted_uri : String, context : HTTP::Server::Context) : Bool
    return context.request.method == "GET" && context.request.uri.path == wanted_uri
  end

  def reply_with_file(context : HTTP::Server::Context, path : String, content_type : String)
    content = File.read(path)
    context.response.content_type = content_type
    context.response.print content
  end

  def reply_with_text(context : HTTP::Server::Context, content : String)
    context.response.content_type = "text/plain"
    context.response.print content
  end

  def get_content_type(file_path : String) : String
    extension = File.extname(file_path).downcase
    case extension
    when ".html"
      "text/html"
    when ".js"
      "application/javascript"
    when ".css"
      "text/css"
    when ".json"
      "application/json"
    when ".png"
      "image/png"
    when ".jpg", ".jpeg"
      "image/jpeg"
    when ".gif"
      "image/gif"
    when ".svg"
      "image/svg+xml"
    when ".ico"
      "image/x-icon"
    when ".woff"
      "font/woff"
    when ".woff2"
      "font/woff2"
    when ".ttf"
      "font/ttf"
    when ".xml"
      "application/xml"
    when ".txt"
      "text/plain"
    else
      "application/octet-stream"
    end
  end

  def serve_file(context : HTTP::Server::Context, root_dir : String, uri_path : String) : Bool
    # Clean up the path to prevent directory traversal
    file_path = File.join(root_dir, uri_path)

    if File.exists?(file_path) && File.file?(file_path)
      content_type = get_content_type(file_path)
      reply_with_file(context, file_path, content_type)
      return true
    end

    false
  end

  def start(root_dir : String)

    server = HTTP::Server.new do |context|

      method = context.request.method
      uri = context.request.uri

      puts "#{method} '#{uri}'"

      replied = false

      # Handle root and special routes
      if get("/", context) || get("/about", context) || get("/contact", context)
        index_html_file = "#{root_dir}/index.html"

        if File.exists?(index_html_file)
          content_type = get_content_type(index_html_file)
          reply_with_file(context, index_html_file, content_type)
        else
          reply_with_text(context, "Mochi Dev Server is running.")
        end
        replied = true
      end

      # Dynamically serve any file based on URI path
      if !replied && method == "GET"
        replied = serve_file(context, root_dir, uri.path.to_s)
      end

      if !replied
        context.response.status = HTTP::Status::NOT_FOUND
        context.response.content_type = "text/plain"
        context.response.print "Error: No handler for #{method} #{uri}"
      end
    end

    address = server.bind_tcp 27490
    puts "Mochi Dev Server listening on http://#{address} with root dir '#{root_dir}'"
    server.listen
  end

end


