require "./HelloWorld.rb"
require "./a/Counter.mo.nb.rb"

class App2

  def html
    %Q{
      <div>
        <HelloWorld/>
        <Counter/>
      </div>
    }
  end

  def css
    %Q{

    }
  end

  def logic
  end

  def mounted
  end
end
