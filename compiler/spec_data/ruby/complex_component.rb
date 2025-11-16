class ComplexComponent
  def initialize
    @items = []
    @users = []
    @count = 0
  end

  def add_item(item)
    @items << item
  end

  def helper_method
    if @count > 0
      puts "positive"
    end
  end

  def render
    "html content"
  end
end
