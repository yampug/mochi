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
