# typed: true
class DevRootBackButton

  @tag_name = "dev-root-back-button"

  def initialize
  end

  def html
    %Q{
      <a href="/" data-external style="margin-right: 10px;">&lt; Go to Root</a>
    }
  end

  def css
    %Q{
        a {
          background: #cf6d6d;
          padding: 10px;
          border-radius: 12px;
          position: absolute;
          right: 10px;
          top: 10px;
          color: white;
          text-decoration: none;
        }
      }
  end

  def mounted
  end

  def unmounted
  end
end
