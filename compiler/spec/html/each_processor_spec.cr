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
    result : EachMatch? = EachProcessor.try_match_each_token(html, 0).not_nil!
    puts "result: '#{result}'"

    check_loop_def(result.loop_def, "@items", "item", nil)
    result.content_start.should eq(21)
    puts result
  end

  it "extract_loop_definition: no index" do
    result : EachLoopDef = EachProcessor.extract_loop_definition("@items as item").not_nil!
    check_loop_def(result, "@items", "item", nil)
  end

  it "extract_loop_definition: with index & space" do
    result : EachLoopDef = EachProcessor.extract_loop_definition("@items as item, index").not_nil!
    check_loop_def(result, "@items", "item", "index")
  end

  it "extract_loop_definition: with index, no space" do
    result : EachLoopDef = EachProcessor.extract_loop_definition("@items as item,index").not_nil!
    check_loop_def(result, "@items", "item", "index")
  end

  it "extract_each_blocks" do
    html = "{each @items as item, index_nr}<li>{item.name}</li>{end}"
    result : Array(EachBlock) = EachProcessor.extract_each_blocks(html).not_nil!
    puts "result: '#{result}'"
    result.size.should eq(1)

    first : EachBlock = result[0]
    check_loop_def(first.loop_def, "@items", "item", "index_nr")
    first.content.should eq("<li>{item.name}</li>")
    first.start_pos.should eq(0)
    first.end_pos.should eq(56)
    first.content_start_pos.should eq(31)
    first.id.should eq(0)
  end

  it "extract_each_blocks: nested" do
    html = "{each @items as item, index_nr}<li>{each @array as entry, k}<div>{entry}</div>{end}</li>{end}"
    result : Array(EachBlock) = EachProcessor.extract_each_blocks(html).not_nil!
    puts "result: '#{result}'"
    result.size.should eq(2)

    first : EachBlock = result[0]
    check_loop_def(first.loop_def, "@array", "entry", "k")
    first.content.should eq("<div>{entry}</div>")
    first.start_pos.should eq(35)
    first.end_pos.should eq(83)
    first.content_start_pos.should eq(60)
    first.id.should eq(1)

    second : EachBlock = result[1]
    check_loop_def(second.loop_def, "@items", "item", "index_nr")
    second.content.should eq("<li>{each @array as entry, k}<div>{entry}</div>{end}</li>")
    second.start_pos.should eq(0)
    second.end_pos.should eq(93)
    second.content_start_pos.should eq(31)
    second.id.should eq(0)
  end

  it "replace_range" do
    result : String = EachProcessor.replace_range(">>>abc<<<", 3, 6, "def")
    result.should eq(">>>def<<<")
    result2 = EachProcessor.replace_range(">>>abc<<<", 6, 3, "123")
    result2.should eq(">>>abc123abc<<<")
  end

  it "process each loops" do
    big_html = %Q{
      <div class="container">
        {each @items as item, index_nr}
          <li>
            {each @array as entry, k}
              <div>{entry}</div>
            {end}
          </li>
        {end}
        <h2>Section 2: Automation</h2>
        {each @items2 as it, j}
          <span>{it}</span>
        {end}
      </div>
    }

    # Only top-level blocks are replaced with comment anchors in the HTML.
    # Nested blocks remain inside the parent block's content template.
    expected_html_after = "\n      <div class=\"container\">\n        <!--each-anchor-0-->\n        <h2>Section 2: Automation</h2>\n        <!--each-anchor-2-->\n      </div>\n    "
    result : EachResult = EachProcessor.process(big_html)
    result.html.should eq(expected_html_after)
    result.each_blocks.size.should eq(3)

    # Blocks are extracted in order of closing {end}, so: inner first (id=1), outer (id=0), then second top-level (id=2)
    inner : EachBlock = result.each_blocks[0]
    check_loop_def(inner.loop_def, "@array", "entry", "k")
    inner.content.should eq("\n              <div>{entry}</div>\n            ")
    inner.start_pos.should eq(98)
    inner.end_pos.should eq(174)
    inner.content_start_pos.should eq(123)
    inner.id.should eq(1)

    outer : EachBlock = result.each_blocks[1]
    check_loop_def(outer.loop_def, "@items", "item", "index_nr")
    # The outer block's content still contains the raw nested {each} token
    outer.content.should contain("{each @array as entry, k}")
    outer.start_pos.should eq(39)
    outer.end_pos.should eq(204)
    outer.content_start_pos.should eq(70)
    outer.id.should eq(0)

    second_top : EachBlock = result.each_blocks[2]
    check_loop_def(second_top.loop_def, "@items2", "it", "j")
    second_top.content.should eq("\n          <span>{it}</span>\n        ")
    second_top.start_pos.should eq(252)
    second_top.end_pos.should eq(317)
    second_top.content_start_pos.should eq(275)
    second_top.id.should eq(2)
  end

end
