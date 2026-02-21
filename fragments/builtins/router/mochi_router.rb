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
                  
                  try {
                    window.history.pushState({}, '', href);
                  } catch (e) {
                    console.warn('MochiRouter: pushState failed (likely due to file:// protocol)', e);
                  }
                  
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
