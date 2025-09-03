# typed: true
# require "text"
# await: true
require 'json'
require "await"
require './lib/sorbet-types/sorbet.rb'
require './lib/sorbet-types/browser.rb'
require "./lib/mochi.rb"

class Counter
  extend T::Sig

  @tag_name = "my-counter"
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
    interval_id = Mochi.interval(proc do
      t = Time.now
      puts "time: #{t}"
  
    end, 1000)
    
    Mochi.timeout(proc do
      Mochi.clear_interval(interval_id)
    end, 5000)
    
    fetcher = Fetcher.create
    
    resp = fetcher.get("/abc").__await__
    `console.log(resp)`
    `console.log(new Map(resp.headers))`
    http_resp = HttpResponse.new(resp)
    puts http_resp
    body = http_resp.body_as_text().__await__
    puts body
    puts http_resp
    puts http_resp.headers()
    
    
    resp2 = fetcher.get("/dummy_json").__await__
    http_resp2 = HttpResponse.new(resp2)
    puts http_resp2
    json =  http_resp2.body_as_hash().__await__
    puts json
  end

  def unmounted
    puts "Counter unmounted"
  end
end
