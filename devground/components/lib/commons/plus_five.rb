# typed: true
require './lib/sorbet-types/sorbet.rb'
require './lib/sorbet-types/browser.rb'
require "./lib/mochi.rb"

class PlusFive
  extend T::Sig

  @tag_name = "plus-five"
  attr_accessor :pfcount

  def initialize
    @pfcount = 0
  end

  sig { returns(Integer) }
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
