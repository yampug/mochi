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

    expected_html_after = %Q{
      <div class="container">
        <mochi-each data-loop-id="0">
          <li>
            <mochi-each data-loop-id="1">
              <div>{entry}</div>
            </mochi-each>
          </li>
        </mochi-each>       {end}
        <h2>Section 2: Automation</h2>
        <mochi-each data-loop-id="2">
          <span>{it}</span>
        </mochi-each>
      </div>
    }
    result : EachResult = EachProcessor.process(big_html)
    puts "result: #{result}"
    result.html.should eq(expected_html_after)
    result.each_blocks.size.should eq(3)

    first : EachBlock = result.each_blocks[0]
    check_loop_def(first.loop_def, "@items2", "it", "j")
    first.content.should eq("\n          <span>{it}</span>\n        ")
    first.start_pos.should eq(252)
    first.end_pos.should eq(317)
    first.content_start_pos.should eq(275)
    first.id.should eq(2)

    second : EachBlock = result.each_blocks[1]
    check_loop_def(second.loop_def, "@array", "entry", "k")
    second.content.should eq("\n              <div>{entry}</div>\n            ")
    second.start_pos.should eq(98)
    second.end_pos.should eq(174)
    second.content_start_pos.should eq(123)
    second.id.should eq(1)

    third : EachBlock = result.each_blocks[2]
    check_loop_def(third.loop_def, "@items", "item", "index_nr")
    third.content.should eq("\n          <li>\n            {each @array as entry, k}\n              <div>{entry}</div>\n            {end}\n          </li>\n        ")
    third.start_pos.should eq(39)
    third.end_pos.should eq(204)
    third.content_start_pos.should eq(70)
    third.id.should eq(0)
  end

end
