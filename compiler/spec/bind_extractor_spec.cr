require "spec"
require "../src/bind_extractor"
require "lexbor"

describe BindExtractor do
  it "get_key_no_prefix" do
    key_no_prefix = BindExtractor.get_key_no_prefix("bind:href")
    key_no_prefix.should eq("href")
  end

  it "get_bind_key" do
    key_no_prefix = BindExtractor.get_bind_key("count")
    key_no_prefix.should eq("count")
    key_no_prefix_2 = BindExtractor.get_bind_key("{count}")
    key_no_prefix_2.should eq("count")
  end

  it "bind extractions: simple" do
    result = BindExtractor.extract("<a bind:href=\"abc\"></a>")
    puts result
    result.html.should eq("<a href=\"abc\"></a>")
    result.bindings.should eq({"abc" => "href"})
  end

  it "bind extractions: nested" do
    result = BindExtractor.extract("<a bind:href='abc'><div bind:airplane=''></div></a>")
    puts result
    result.html.should eq("<a href=\"abc\"><div airplane=\"\"></div></a>")
    result.bindings.should eq({"abc" => "href"})
  end

  it "bind extractions: multiple binds" do
    result = BindExtractor.extract("<a bind:href='abc' bind:text='def'></a>")
    puts result
    result.html.should eq("<a href=\"abc\" text=\"def\"></a>")
    result.bindings.should eq({"abc" => "href", "def" => "text"})
  end

  it "bind extractions: big" do
    result = BindExtractor.extract("<div class=\"wrapper\">
        <h1>Count123: {count}</h1>
        <h2>Modifications: {modifications}</h2>
        {if @count > 5}
          <p style=\"border-radius: 8px;\">Count is greater than 5!</p>
        {end}
        {if @count < 0}
          <p style=\"border-radius: 8px;\">Count is negative!</p>
        {end}
        <button onclick={increment}>Increment</button>
        <button onclick={decrement}>Decrement</button>
        <plus-five bind:pfcount=\"{count}\"></plus-five>
        <input value={count} onchange={input_changed} type=\"text\"></input>
      </div>")
    puts result
    result.html.should eq("<div class=\"wrapper\">
        <h1>Count123: {count}</h1>
        <h2>Modifications: {modifications}</h2>
        {if @count &gt; 5}
          <p style=\"border-radius: 8px;\">Count is greater than 5!</p>
        {end}
        {if @count &lt; 0}
          <p style=\"border-radius: 8px;\">Count is negative!</p>
        {end}
        <button onclick=\"{increment}\">Increment</button>
        <button onclick=\"{decrement}\">Decrement</button>
        <plus-five pfcount=\"{count}\"></plus-five>
        <input value=\"{count}\" onchange=\"{input_changed}\" type=\"text\">
      </div>")
    result.bindings.should eq({"count" => "pfcount"})
  end
end
