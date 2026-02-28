# typed: true
class FeatherIcon

  @tag_name = "feather-icon"
  @icon
  @rendered_svg

  attr_accessor :icon
  
  def initialize
    @icon = ""
    @rendered_svg = ""
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

  def mounted(comp)
    @rendered_svg = `feather.icons[#{@icon}].toSvg([])`
    `#{comp}.syncAttributes()`
  end

  def unmounted
  end
end
