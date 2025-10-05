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

      result.html.should contain("<mochi-if data-condition=\"@show\">")
      result.html.should contain("<p>Visible!</p>")
      result.html.should contain("</mochi-if>")
      result.conditionals.size.should eq(1)
      result.conditionals[0].condition.should eq("@show")
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
      result.html.should contain("data-condition=\"@show\"")
      result.html.should contain("data-condition=\"@display\"")
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
      # Should have both conditions transformed
      result.html.should contain("data-condition=\"@show\"")
      result.html.should contain("data-condition=\"@nested\"")
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
      # > should be escaped in HTML attribute
      result.html.should contain("data-condition=\"@count &gt; 5\"")
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
end
