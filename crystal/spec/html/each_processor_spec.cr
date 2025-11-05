require "spec"
require "../../src/html/each_processor"

def self.check_loop_def(loop_def : EachLoopDef, array_name : String, item_name : String, index_name : String?)
  loop_def.array_name.should eq(array_name)
  loop_def.item_name.should eq(item_name)
  loop_def.index_name.should eq(index_name)
end

describe EachProcessor do

  it "try_match_each_token: one element" do
    html = "{each @items as item}<li>{item.name}</li>{end}"
    result = EachProcessor.try_match_each_token(html, 0).not_nil!
    puts "result: '#{result}'"

    check_loop_def(result.loop_def, "@items", "item", nil)
    result.content_start.should eq(21)
    puts result
  end

  it "extract_loop_definition: no index" do
    result = EachProcessor.extract_loop_definition("@items as item").not_nil!
    check_loop_def(result, "@items", "item", nil)
  end

  it "extract_loop_definition: with index & space" do
    result = EachProcessor.extract_loop_definition("@items as item, index").not_nil!
    check_loop_def(result, "@items", "item", "index")
  end

  it "extract_loop_definition: with index, no space" do
    result = EachProcessor.extract_loop_definition("@items as item,index").not_nil!
    check_loop_def(result, "@items", "item", "index")
  end

  it "extract_each_blocks" do
    html = "{each @items as item, index_nr}<li>{item.name}</li>{end}"
    result = EachProcessor.extract_each_blocks(html).not_nil!
    puts "result: '#{result}'"
    result.size.should eq(1)

    first = result[0]
    check_loop_def(first.loop_def, "@items", "item", "index_nr")
    first.content.should eq("<li>{item.name}</li>")
    first.start_pos.should eq(0)
    first.end_pos.should eq(56)
    first.content_start_pos.should eq(31)
    first.id.should eq(0)
  end

  it "extract_each_blocks: nested" do
    html = "{each @items as item, index_nr}<li>{each @array as entry, k}<div>{entry}</div>{end}</li>{end}"
    result = EachProcessor.extract_each_blocks(html).not_nil!
    puts "result: '#{result}'"
    result.size.should eq(2)

    first = result[0]
    check_loop_def(first.loop_def, "@array", "entry", "k")
    first.content.should eq("<div>{entry}</div>")
    first.start_pos.should eq(35)
    first.end_pos.should eq(83)
    first.content_start_pos.should eq(60)
    first.id.should eq(1)

    second = result[1]
    check_loop_def(second.loop_def, "@items", "item", "index_nr")
    second.content.should eq("<li>{each @array as entry, k}<div>{entry}</div>{end}</li>")
    second.start_pos.should eq(0)
    second.end_pos.should eq(93)
    second.content_start_pos.should eq(31)
    second.id.should eq(0)
  end

end
