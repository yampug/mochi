require "spec"
require "../../src/html/attribute_conditional_extractor"

describe AttributeConditionalExtractor do
  describe ".process" do
    it "extracts a single conditional attribute" do
      html = %Q{<a class="nav-item {if @active}active{end}">Link</a>}
      result = AttributeConditionalExtractor.process(html)
      
      result.conditionals.size.should eq 1
      cond = result.conditionals[0]
      cond.id.should eq 0
      cond.attribute_name.should eq "class"
      cond.original_string.should eq "nav-item {if @active}active{end}"
      
      result.html.should eq %Q{<a class="{__mochi_attr_cond_0}">Link</a>}
    end

    it "extracts multiple conditional attributes" do
      html = %Q{<div class="{if @a}a{end}" data-val='{unless @b}b{end}'></div>}
      result = AttributeConditionalExtractor.process(html)
      
      result.conditionals.size.should eq 2
      
      cond0 = result.conditionals[0]
      cond0.attribute_name.should eq "class"
      cond0.original_string.should eq "{if @a}a{end}"
      
      cond1 = result.conditionals[1]
      cond1.attribute_name.should eq "data-val"
      cond1.original_string.should eq "{unless @b}b{end}"
      
      result.html.should eq %Q{<div class="{__mochi_attr_cond_0}" data-val='{__mochi_attr_cond_1}'></div>}
    end

    it "leaves attributes without conditionals alone" do
      html = %Q{<a class="nav-item" href="{url}">Link</a>}
      result = AttributeConditionalExtractor.process(html)
      
      result.conditionals.size.should eq 0
      result.html.should eq html
    end

    it "leaves block conditionals alone" do
      html = %Q{<div>{if @active}<span>Active</span>{end}</div>}
      result = AttributeConditionalExtractor.process(html)
      
      result.conditionals.size.should eq 0
      result.html.should eq html
    end

    it "handles conditionals with multiple branches (even if not strictly supported yet)" do
      html = %Q{<a class="nav {if @x}x{elsif @y}y{else}z{end}">Link</a>}
      result = AttributeConditionalExtractor.process(html)
      
      result.conditionals.size.should eq 1
      result.html.should eq %Q{<a class="{__mochi_attr_cond_0}">Link</a>}
      result.conditionals[0].original_string.should eq "nav {if @x}x{elsif @y}y{else}z{end}"
    end
  end
end
