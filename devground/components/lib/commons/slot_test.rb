# typed: true

class SlotTest
  @tag_name = "slot-test"
  @title

  def initialize
    @title = "Slot Container"
  end

  def html
    %Q{
      <div class="slot-container">
        <h2>{title}</h2>
        <div class="slot-wrapper">
          <slot></slot>
        </div>
      </div>
    }
  end

  def css
    %Q{
      .slot-container {
        background: #f0f0f0;
        padding: 20px;
        border: 2px solid #333;
        border-radius: 8px;
        margin: 10px;
      }

      .slot-wrapper {
        background: white;
        padding: 15px;
        border-radius: 4px;
        margin-top: 10px;
      }

      h2 {
        margin: 0 0 10px 0;
        color: #333;
      }
    }
  end

  def mounted(comp)
    puts "SlotTest mounted - slots should work!"
  end

  def unmounted
    puts "SlotTest unmounted"
  end
end
