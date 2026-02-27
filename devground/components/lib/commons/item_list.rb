# typed: true
require 'json'
require "./lib/mochi.rb"

class ItemList

  @tag_name = "item-list"
  @items
  @counter

  def initialize
    @items = []
    @counter = 0
    add_initial_items
  end

  def add_initial_items
    add_item_with_data(1, "Apple", "A delicious red fruit")
    add_item_with_data(2, "Banana", "A yellow tropical fruit")
    add_item_with_data(3, "Orange", "A citrus fruit")
  end

  def add_item_with_data(id, name, description)
    item = `{ id: #{id}, name: #{name}, description: #{description} }`
    @items.push(item)
  end

  def html
    %Q{
      <div class="wrapper">
        <h2>Item List (Each Block Demo)</h2>
        <p>Counter: {counter}</p>
        <button onclick="{add_item}">Add Item</button>
        <button onclick="{remove_item}">Remove Item</button>

        <div class="items">
          {each @items as item, index}
            <div>{index}</div>
          {end}
        </div>

        {if @items.length == 0}
          <p class="empty-message">No items to display. Add some items!</p>
        {end}
      </div>
    }
  end

  def css
    %Q{
      .wrapper {
        background: #f5f5f5;
        padding: 20px;
        border-radius: 12px;
        margin-bottom: 20px;
        max-width: 600px;
      }

      h2 {
        color: #333;
        margin-top: 0;
      }

      button {
        background: #4CAF50;
        color: white;
        border: none;
        padding: 10px 20px;
        border-radius: 6px;
        cursor: pointer;
        margin-right: 10px;
        margin-bottom: 15px;
      }

      button:hover {
        background: #45a049;
      }

      .items {
        margin-top: 20px;
      }

      .item-card {
        background: white;
        padding: 15px;
        margin-bottom: 10px;
        border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      }

      .item-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
      }

      .item-header h3 {
        margin: 0;
        color: #2196F3;
      }

      .item-id {
        background: #e3f2fd;
        padding: 4px 8px;
        border-radius: 4px;
        font-size: 12px;
        color: #1976D2;
      }

      .item-description {
        margin: 10px 0 0 0;
        color: #666;
      }

      .item-index {
        margin: 5px 0 0 0;
        font-size: 12px;
        color: #999;
      }

      .empty-message {
        background: #fff3cd;
        padding: 15px;
        border-radius: 8px;
        color: #856404;
        text-align: center;
        margin-top: 20px;
      }
    }
  end

  def add_item
    @counter = @counter + 1
    new_id = @items.length + 1
    add_item_with_data(new_id, "Item #{new_id}", "Description for item #{new_id}")
    puts "Added item: Item #{new_id}"
  end

  def remove_item
    if @items.length > 0
      removed = @items.pop
      @counter = @counter - 1
      item_name = `#{removed}.name`
      puts "Removed item: #{item_name}"
    end
  end

  def mounted(web_component)
    puts "ItemList mounted with #{@items.length} items"
  end

  def unmounted
    puts "ItemList unmounted"
  end

end
