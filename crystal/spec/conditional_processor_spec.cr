require "spec"
require "../src/html/conditional_processor"

describe ConditionalProcessor do
  describe ".process" do
    it "processes simple if condition" do
      html = %Q{
        <div>
          {if @show}
            <p>Visible!</p>
          {end}
        </div>
      }

      result = ConditionalProcessor.process(html)

      result.html.should contain("<mochi-if data-cond-id=\"0\">")
      result.html.should contain("<p>Visible!</p>")
      result.html.should contain("</mochi-if>")
      result.conditionals.size.should eq(1)
      result.conditionals[0].condition.should eq("@show")
      result.conditionals[0].id.should eq(0)
    end

    it "processes multiple if conditions" do
      html = %Q{
        <div>
          {if @show}
            <p>First</p>
          {end}
          {if @display}
            <p>Second</p>
          {end}
        </div>
      }

      result = ConditionalProcessor.process(html)

      result.conditionals.size.should eq(2)
      result.html.should contain("data-cond-id=\"0\"")
      result.html.should contain("data-cond-id=\"1\"")
      # Blocks are sorted by reverse start position, so order may differ
      # Just verify both IDs exist
      ids = result.conditionals.map(&.id).sort
      ids.should eq([0, 1])
    end

    it "processes nested if conditions" do
      html = %Q{
        <div>
          {if @show}
            <div>
              {if @nested}
                <p>Nested content</p>
              {end}
            </div>
          {end}
        </div>
      }

      result = ConditionalProcessor.process(html)

      result.conditionals.size.should eq(2)
      # Should have both conditions transformed with IDs
      result.html.should contain("data-cond-id=\"0\"")
      result.html.should contain("data-cond-id=\"1\"")
      # Blocks are sorted by reverse start position, so verify both IDs exist
      ids = result.conditionals.map(&.id).sort
      ids.should eq([0, 1])
    end

    it "processes condition with comparison operators" do
      html = %Q{
        <div>
          {if @count > 5}
            <p>Greater than 5</p>
          {end}
        </div>
      }

      result = ConditionalProcessor.process(html)

      result.conditionals.size.should eq(1)
      result.conditionals[0].condition.should eq("@count > 5")
      result.conditionals[0].id.should eq(0)
      # No need to escape in data-cond-id, just use ID
      result.html.should contain("data-cond-id=\"0\"")
    end

    it "processes condition with method calls" do
      html = %Q{
        <div>
          {if @items.empty?}
            <p>No items</p>
          {end}
        </div>
      }

      result = ConditionalProcessor.process(html)

      result.conditionals.size.should eq(1)
      result.conditionals[0].condition.should eq("@items.empty?")
    end

    it "handles HTML without conditionals" do
      html = %Q{
        <div>
          <p>No conditionals here</p>
        </div>
      }

      result = ConditionalProcessor.process(html)

      result.conditionals.size.should eq(0)
      result.html.should eq(html)
    end

    it "preserves whitespace and formatting" do
      html = %Q{
        <div class="wrapper">
          {if @show}
            <h1>Title</h1>
            <p>Paragraph</p>
          {end}
        </div>
      }

      result = ConditionalProcessor.process(html)

      result.html.should contain("<h1>Title</h1>")
      result.html.should contain("<p>Paragraph</p>")
    end
  end

  describe ".extract_conditionals" do
    it "extracts single conditional block" do
      html = "{if @show}<p>Content</p>{end}"
      blocks = ConditionalProcessor.extract_conditionals(html)

      blocks.size.should eq(1)
      blocks[0].condition.should eq("@show")
      blocks[0].content.should eq("<p>Content</p>")
    end

    it "extracts nested conditional blocks" do
      html = "{if @outer}{if @inner}<p>Nested</p>{end}{end}"
      blocks = ConditionalProcessor.extract_conditionals(html)

      blocks.size.should eq(2)
    end

    it "handles multiple separate blocks" do
      html = "{if @a}<p>A</p>{end}{if @b}<p>B</p>{end}"
      blocks = ConditionalProcessor.extract_conditionals(html)

      blocks.size.should eq(2)
    end
  end

  it "try_match_if_token: one element" do
    html = "{if @abc}<span>Thomas</span>{end}"
    result = ConditionalProcessor.try_match_if_token(html, 0).not_nil!
    puts "result:'#{result}'"
    result.condition.should eq("@abc")
    result.content_start.should eq(9)

    result2 = ConditionalProcessor.try_match_if_token(html, 1)
    puts "result2:'#{result2}'"
    result2.should eq(nil)
  end
end
