require "a/hello_sayer"
# typed: true

class MochiBrowserUtils

  @tag_name = "mochi-browser-utils"
  @pfcount

  def initialize
    @pfcount = 0
  end

  def reactables
    ["pfcount"]
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

  def increment
    @pfcount = @pfcount + 1
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
