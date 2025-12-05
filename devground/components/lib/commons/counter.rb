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
        {if @count > 5}
          <p style="background: green; padding: 10px; border-radius: 8px;">Count is greater than 5!</p>
        {end}
        {if @count < 0}
          <p style="background: orange; padding: 10px; border-radius: 8px;">Count is negative!</p>
        {end}
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
  end

  def decrement
    @count = @count - 1
    @modifications = @modifications + 1
  end

  def mounted(web_component)
    puts "Counter mounted"
    interval_id = Mochi.interval(proc do
      t = Time.now
      puts "time: #{t}"
  
    end, 1000)
    
    Mochi.timeout(proc do
      Mochi.clear_interval(interval_id)
    end, 5000)
    
    if false
    # fetcher stuff
      fetcher = Fetcher.create
      
      http_resp = fetcher.fetch("/abc", FetchConfigBuilder.new().build()).__await__
      #`console.log(resp)`
      #`console.log(new Map(resp.headers))`
      #http_resp = HttpResponse.new(resp)
      puts http_resp
      body = http_resp.body_as_text().__await__
      puts body
      puts http_resp
      puts http_resp.headers()
      
      config = FetchConfigBuilder.new()
        .set_method("GET")
        .set_headers({
          "Abc": "def"
        })
        .set_keep_alive(true)
        .build()
      `console.log(config)`
      http_resp2 = fetcher.fetch("/dummy_json", config).__await__
      puts http_resp2
      hash =  http_resp2.body_as_hash().__await__
      puts hash
    end
    browser = BrowserIdentifier.identify
    puts "Browser: #{browser}"
  end

  def unmounted
    puts "Counter unmounted"
  end
end
