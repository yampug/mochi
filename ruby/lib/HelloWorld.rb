
class HelloWorld

  def html
    %Q{
      <div>
        <h2>Hello from Ruby!</h2>
      </div>
    }
  end

  def css
    %Q{
      h2 {
        color: red;
      }

      h3 {
        color: black;
      }
    }
  end

  def logic
    puts 'Logic executed!'
    if true
      puts "2"
    end
  end

  def mounted
    puts "Mounted HelloWorld"
    logic
  end
end
