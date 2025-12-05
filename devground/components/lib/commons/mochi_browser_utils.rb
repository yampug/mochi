require "commons/hello_sayer"
# typed: true

class MochiBrowserUtils

  @tag_name = "mochi-browser-utils"

  def initialize
  end

  def reactables
    []
  end

  def html
    %Q{
      <div>
        Mochi Browser Utils
      </div>
    }
  end

  def css
    %Q{

    }
  end

  def mounted
    a = Mochi.window
    Log.object(self, a)
    b = Mochi.document
    Log.object(self, b)
  end

  def unmounted
  end
end
