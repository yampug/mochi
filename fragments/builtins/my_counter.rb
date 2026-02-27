class MyCounter

  @tag_name = "my-counter"
  @count

  def initialize
    @count = 0
  end

  def html
    %Q{
          <div class="wrapper">
            <h1>Count: {count}</h1>
            <button onclick="{increment}">Increment</button>
            <button onclick="{decrement}">Decrement</button>
          </div>
        }
  end

  def css
    %Q{
          .wrapper {
            background: linear-gradient(45deg, black, #f37b812e);
            color: white;
            padding: 30px;
            border-radius: 8px;
            border: 1px solid #623c3c;
          }
          button {
            border: 1px solid #ff92b3;
            padding: 8px 10px;
            border-radius: 8px;
            color: white;
            cursor: pointer;
            background: #a53269;
          }
          button:hover {
            background: #c7588d;
          }
        }
  end

  def increment
    @count = @count + 1
  end

  def decrement
    @count = @count - 1
  end

  def mounted
    puts "MyCounter mounted"
  end

  def unmounted
    puts "MyCounter unmounted"
  end
end
