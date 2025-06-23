# typed: true
# require "text"
require './lib/sorbet-types/srb_type_opal.rb'
require './lib/sorbet-types/srb_type_browser.rb'

class Counter
  extend T::Sig

  @cmp_name = "my-counter"
  @count
  @modifications

  def initialize
    @count = 0
    @modifications = 0
    # puts Text::Levenshtein.distance('test', 'test')
  end

  sig { returns(T::Array[String]) }
  def reactables
    ["count", "modifications"]
  end

  sig { returns(String) }
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

  sig { returns(String) }
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
    
    url = 'https://www.ign.com'
    
    puts "Making a GET request to: #{url}"
    
    # Browser::HTTP.get(url).then do |response|
    #   if response.ok?
    #     puts "Request successful with status: #{response.status_code}"
    #     response.text.then do |text_data|
    #       puts "Response text received:"
    #       puts text_data
    #     end
    
    #   else
    #     puts "Request failed with status: #{response.status_code}"
    #   end
    # end.catch do |error|
    #   puts "An error occurred during the request:"
    #   puts error.message
    # end

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
