class ALayout

  @tag_name = "app-layout"

  def initialize
    @current_page = "wsb-overview"
    @page_title = "WSB Overview"
    @page_content = "<wsb-content></wsb-content>"
    @wsb_expanded = true
    @submenu_class = "expanded"
    @wsb_arrow = "▼"
    @wsb_active_class = "active"
  end

  def reactables
    ["current_page", "page_title", "page_content", "wsb_expanded", "submenu_class", "wsb_arrow", "wsb_active_class"]
  end

  def html
    %Q{
      <div class="app-container">
        <aside class="sidebar">
          <div class="logo-section">
            <div class="logo">Big Corp</div>
          </div>
          <nav class="menu">
            <div class="menu-group">
              <div class="menu-item {wsb_active_class}" onclick={toggle_wsb}>
                <span class="menu-icon">📊</span>
                <span class="menu-text">WSB</span>
                <span class="menu-arrow">{wsb_arrow}</span>
              </div>
              <div class="submenu {submenu_class}">
                <div class="submenu-item {get_active_class('wsb-overview')}" onclick={navigate_to_wsb_overview}>
                  <span class="submenu-text">Overview</span>
                </div>
                <div class="submenu-item {get_active_class('wsb-feed')}" onclick={navigate_to_wsb_feed}>
                  <span class="submenu-text">Feed</span>
                </div>
              </div>
            </div>
            <div class="menu-item {get_active_class('watchlist')}" onclick={navigate_to_watchlist}>
              <span class="menu-icon">⭐</span>
              <span class="menu-text">Watchlist</span>
            </div>
          </nav>
        </aside>
        <main class="content">
          <div class="content-header">
            <h1>{page_title}</h1>
          </div>
          <div class="content-body">
            {page_content}
          </div>
        </main>
      </div>
    }
  end

  def css
    %Q{

    }
  end

  def get_active_class(page)
    @current_page == page ? "active" : ""
  end

  def toggle_wsb
    @wsb_expanded = !@wsb_expanded
    @submenu_class = @wsb_expanded ? "expanded" : ""
    @wsb_arrow = @wsb_expanded ? "▼" : "▶"
  end

  def update_wsb_active_state
    @wsb_active_class = (@current_page == "wsb-overview" || @current_page == "wsb-feed") ? "active" : ""
  end

  def navigate_to_wsb_overview
    @current_page = "wsb-overview"
    @page_title = "WSB Overview"
    @page_content = "<wsb-content></wsb-content>"
    @wsb_expanded = true
    @submenu_class = "expanded"
    @wsb_arrow = "▼"
    @wsb_active_class = "active"
  end

  def navigate_to_wsb_feed
    @current_page = "wsb-feed"
    @page_title = "WSB Feed"
    @page_content = "<wsb-feed></wsb-feed>"
    @wsb_expanded = true
    @submenu_class = "expanded"
    @wsb_arrow = "▼"
    @wsb_active_class = "active"
  end

  def navigate_to_watchlist
    @current_page = "watchlist"
    @page_title = "Watchlist"
    @page_content = "<watchlist-content></watchlist-content>"
    @wsb_active_class = ""
  end

  def mounted
    puts "ALayout mounted"
  end

  def unmounted
    puts "ALayout unmounted"
  end
end
