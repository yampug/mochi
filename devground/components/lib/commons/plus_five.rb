# typed: true
class PlusFive

  @tag_name = "plus-five"
  @pfcount

  def initialize
    @pfcount = 0
  end

  def reactables
    ["pfcount"]
  end

  sig {().returns(Integer) }
  def html
    %Q{
      <div class="plus-five">
        <button on:click={increment}>Increment</button>
        <div>pfcount: {pfcount}</div>
      </div>
    }
  end

  def css
    %Q{
      .plus-five {
        background: yellow;
      }
    }
  end

  def increment
    @pfcount = @pfcount + 1
  end

  def mounted
    puts "PlusFive mounted"
  end

  def unmounted
    puts "PlusFive unmounted"
  end
end
