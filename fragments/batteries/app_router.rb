class AppRouter
  def initialize(&block)
    @routes = []
    instance_eval(&block) if block_given?
  end

  def on(path_pattern, &handler)
    names, regex = compile_path(path_pattern)
    @routes << { names: names, regex: regex, handler: handler }
  end

  def not_found(&handler)
    @not_found_handler = handler
  end

  def compile_path(path_pattern)
    names = []
    # Turn /users/:id into a regex
    regex_string = path_pattern.gsub(/:\w+/) do |match|
      # Store the name of the parameter (e.g., "id")
      names << match.tr(':', '')
      # Replace it with a capture group
      '([^\/]+)'
    end

    # Ensure it matches the full path
    [names, Regexp.new("^#{regex_string}$")]
  end

  def resolve
    path = `window.location.pathname`
    query_params = `window.location.search`
    resolve_manual(path, query_params)
  end

  def resolve_manual(path, query_params)
    @routes.each do |route|
      match_data = path.match(route[:regex])

      # If the regex matches the path...
      if match_data
        # Create the params hash
        # e.g., ["id"] and ["123"] => {"id" => "123"}
        params = Hash[route[:names].zip(match_data.captures)]

        # Call the stored block with the params
        return route[:handler].call(params)
      end
    end

    # If no route was found, call the not_found handler
    @not_found_handler.call if @not_found_handler
  end
end
