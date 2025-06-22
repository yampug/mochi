# require "text"
#require 'opal-browser'

class Counter

  @cmp_name = "my-counter"
  @count
  @modifications

  def initialize
    @count = 0
    @modifications = 0
    # puts Text::Levenshtein.distance('test', 'test')
  end

  def reactables
    ["count", "modifications"]
  end

  def html
    %Q{
      <div class="wrapper">
        <h1>Count123: {count}</h1>
        <h2>Modifications: {modifications}</h2>
        <button on:click={increment}>Increment</button>
        <button on:click={decrement}>Decrement</button>
        <plus-five bind:pfcount="{count}"></plus-five>
        <input value={count} on:change={input_changed} type="text"></input>
      </div>
    }
  end

  def css
    %Q{
      .wrapper {
        background: red;
        width: 200px;
        padding: 10px;
        margin-bottom: 5px;
        border-radius: 14px;
      }
      .plus-five {
        background: green;

      }
    }
  end

  def input_changed(e, value)
    puts "input changed: #{e}: #{value}"
    @count = @count + value
  end

  def increment
    @count = @count + 1
    @modifications = @modifications + 1
    
    url = 'http://example.org'
    
    puts "Making a GET request to: #{url}"
    
    # HTTP.get returns a Promise-like object.
    # We use .then to handle a successful response and .catch for errors.
    Browser::HTTP.get(url).then do |response|
      # The 'response' object gives you access to the status, body, etc.
      if response.ok?
        puts "Request successful with status: #{response.status_code}"
    
        # To get the body as a JSON object (automatically parsed):
        # This returns another promise, so we chain it.
        # response.json.then do |data|
        #   # puts "Response JSON received:"
        #   # # The data is now a standard Ruby Hash or Array
        #   # puts "User ID: #{data['userId']}"
        #   # puts "Title: #{data['title']}"
        # end
    
        # Or to get the body as plain text:
        response.text.then do |text_data|
          puts "Response text received:"
          puts text_data
        end
    
      else
        puts "Request failed with status: #{response.status_code}"
      end
    end.catch do |error|
      # This block runs if the network request itself fails
      # (e.g., network down, DNS error).
      puts "An error occurred during the request:"
      puts error.message
    end

  end

  def decrement
    @count = @count - 1
    @modifications = @modifications + 1
  end

  def mounted
    puts "Counter mounted"
  end

  def unmounted
    puts "Counter unmounted"
  end
end
