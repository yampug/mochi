require "spec"
require "../../src/html/each_processor"

describe EachProcessor do

  it "try_match_each_token: one element" do
    html = "{each @items as item}<li>{item.name}</li>{end}"

    result = EachProcessor.try_match_each_token(html, 0).not_nil!
    puts "result: '#{result}'"

    result.loop_def.array_name.should eq("@items")
    result.loop_def.item_name.should eq("item")
    result.loop_def.index_name.should eq(nil)
    result.content_start.should eq(21)
    puts result
  end

  it "extract_loop_definition: no index" do
    result = EachProcessor.extract_loop_definition("@items as item").not_nil!
    result.array_name.should eq("@items")
    result.item_name.should eq("item")
    result.index_name.should eq(nil)
  end

  it "extract_loop_definition: with index & space" do
    result = EachProcessor.extract_loop_definition("@items as item, index").not_nil!
    result.array_name.should eq("@items")
    result.item_name.should eq("item")
    result.index_name.should eq("index")
  end

  it "extract_loop_definition: with index, no space" do
    result = EachProcessor.extract_loop_definition("@items as item,index").not_nil!
    result.array_name.should eq("@items")
    result.item_name.should eq("item")
    result.index_name.should eq("index")
  end

end
