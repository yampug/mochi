class RubyRewriter

  def initialize
  end
  
  def rewrite : String
    ""
  end
  
  def extract_lib_path(path : String) : String?
  
    result = nil
    if index = path.index("lib/")
      # Take a slice from that index to the end of the string
      result = path[index..]
    end
    return result
  end
  
  def format_require_path(path : String) : String
    path
      .sub(/^lib\//, "")
      .sub(/\.rb$/, "")
  end
  
  def gen_mochi_ruby_root(components : Array(MochiComponent)) : String
    rb_code = ""
    
    rb_code += "require 'opal'\n"
    rb_code += "require 'native'\n"
    rb_code += "require 'promise'\n"
    rb_code += "require 'browser/setup/full'\n"

    components.each do |mochi_comp|
      lib_path = extract_lib_path(mochi_comp.absolute_path)
      if lib_path
        rb_code += "require \"#{format_require_path(lib_path)}\"\n"
      end
    end
    
    rb_code += "class Root\n"
    rb_code += "end\n"
    
    rb_code += "\n"
    components.each do |mochi_comp|
      rb_code += "#{mochi_comp.name}.new\n"
    end
    
    rb_code
  end

  def gen_builtin_component_feather_icon() : String
    <<-'RUBY'
      # typed: true
      class FeatherIcon

        @tag_name = "feather-icon"
        @icon
        @rendered_svg

        def initialize
          @icon = ""
          @rendered_svg = ""
        end

        def reactables
          ["icon", "rendered_svg"]
        end

        def html
          %Q{
            <div class="feather-icon">
              {rendered_svg}
            </div>
          }
        end

        def css
          %Q{
            .feather-icon {
            }
          }
        end

        def mounted(shadow_root, comp)
          @rendered_svg = `feather.icons[#{@icon}].toSvg([])`
          `#{comp}.syncAttributes()`
        end

        def unmounted
        end
      end

    RUBY
  end

  def gen_builtin_mochi_router() : String
    <<-'RUBY'
      # typed: true

      class MochiRouter
        @tag_name = "mochi-router-internal"
        @@current_path = ""
        @@observers = []
        @@initialized = false

        def initialize
        end

        # Dummy methods to satisfy the transpiler (not actually rendered)
        def reactables
          []
        end

        def html
          %Q{
            <div style="display: none;"></div>
          }
        end

        def css
          %Q{
            :host {
              display: none;
            }
          }
        end

        def mounted(shadow_root, comp)
        end

        def unmounted
        end

        # Subscribe a route component to path changes
        def self.subscribe(observer)
          @@observers << observer
        end

        # Unsubscribe a route component (called on unmount)
        def self.unsubscribe(observer)
          @@observers.delete(observer)
        end

        # Navigate to a new path
        def self.navigate(path)
          @@current_path = path

          # Notify all route components
          @@observers.each { |obs| obs.on_route_change(path) }
        end

        # Get current path
        def self.current_path
          @@current_path
        end

        # Initialize browser listeners (called by first route to mount)
        def self.init_browser_listeners_once
          return if @@initialized
          @@initialized = true

          puts "MochiRouter: Initializing browser listeners"

          # Listen to browser back/forward
          `
            window.addEventListener('popstate', () => {
              let path = window.location.pathname;
              console.log('MochiRouter: popstate event, path:', path);
              Opal.MochiRouter.$navigate(path);
            });

            // Handle link clicks
            document.addEventListener('click', (e) => {
              // Find the closest <a> tag (in case user clicked on child element)
              let target = e.target.closest('a');

              if (target && target.tagName === 'A') {
                // Check if it's an internal link (relative or same origin)
                let href = target.getAttribute('href');

                if (href && !href.startsWith('http://') && !href.startsWith('https://') && !href.startsWith('//')) {
                  e.preventDefault();
                  console.log('MochiRouter: navigating to', href);
                  window.history.pushState({}, '', href);
                  Opal.MochiRouter.$navigate(href);
                }
              }
            });
          `

          # Set initial path from browser
          current = `window.location.pathname`
          @@current_path = current
          puts "MochiRouter: Initial path set to '#{current}'"
        end
      end

    RUBY
  end

  def gen_builtin_route_component() : String
    <<-'RUBY'
      # typed: true

      class Route
        @tag_name = "mochi-route"
        @match
        @active
        @component_ref

        def initialize
          @match = ""
          @active = false
          @component_ref = nil
        end

        def reactables
          ["active"]
        end

        def html
          %Q{
            <div class="route-content">
              <slot></slot>
            </div>
          }
        end

        def css
          %Q{
            :host {
              display: block;
            }

            .route-content {
              width: 100%;
              height: 100%;
            }

            .route-content.hidden {
              display: none;
            }
          }
        end

        def mounted(shadow_root, comp)
          @component_ref = comp

          match_attr = Mochi.get_attr(comp, "match")
          @match = match_attr || "/"

          ::MochiRouter.init_browser_listeners_once

          ::MochiRouter.subscribe(self)

          check_match(::MochiRouter.current_path)
        end

        def unmounted
          ::MochiRouter.unsubscribe(self)
        end

        def on_route_change(path)
          check_match(path)
        end

        private

        def check_match(path)
          was_active = @active

          if matches_path?(path)
            @active = true
          else
            @active = false
          end

          # Update DOM directly
          if @component_ref
            content_div = `#{@component_ref}.shadow.querySelector('.route-content')`
            if @active
              `#{content_div}.classList.remove('hidden')`
            else
              `#{content_div}.classList.add('hidden')`
            end
          end
        end

        def matches_path?(path)
          # Exact match for now
          # TODO: Expand with dynamic segments like :id
          @match == path || @match == "*"
        end
      end

    RUBY
  end
  
  def comment_out_sorbet_signatures(ruby_code : String) : String
    ruby_code.each_line.map do |line|
      if line.strip.starts_with?("sig {")
        "#" + line
      else
        line
      end
    end.join("\n")
  end
  
  def comment_out_all_sorbet_signatures_in_dir(path : String)
    unless File.directory?(path)
      STDERR.puts "Error: Provided path is not a directory -> #{path}"
      return
    end
    
    Dir.each_child(path) do |child|
      full_path = File.join(path, child)
  
      if File.directory?(full_path)
        comment_out_all_sorbet_signatures_in_dir(full_path)
      elsif File.file?(full_path)
        begin
          content = File.read(full_path)
          File.write(full_path, comment_out_sorbet_signatures(content))
        rescue ex
          STDERR.puts "  -> Could not write to file: #{full_path}. Reason: #{ex.message}"
        end
      end
    end
  end
  
end