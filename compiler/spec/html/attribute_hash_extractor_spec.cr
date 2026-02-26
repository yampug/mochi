require "../../src/html/attribute_hash_extractor"

describe AttributeHashExtractor do
  it "extracts hash attributes without quotes" do
    html = %Q(<div class={{ "nav-item" => true, "active" => @is_active }}>)
    result = AttributeHashExtractor.process(html)
    
    result.html.should eq %Q(<div class="{__mochi_attr_hash_0}">)
    result.hashes.size.should eq 1
    
    hash = result.hashes.first
    hash.id.should eq 0
    hash.attribute_name.should eq "class"
    hash.original_string.should eq %Q({{ "nav-item" => true, "active" => @is_active }})
  end

  it "extracts hash attributes with double quotes" do
    html = %Q(<div class="{{ 'nav-item' => true, 'active' => @is_active }}">)
    result = AttributeHashExtractor.process(html)
    
    result.html.should eq %Q(<div class="{__mochi_attr_hash_0}">)
    result.hashes.size.should eq 1
    
    hash = result.hashes.first
    hash.id.should eq 0
    hash.attribute_name.should eq "class"
    hash.original_string.should eq %Q({{ 'nav-item' => true, 'active' => @is_active }})
  end

  it "leaves regular attributes untouched" do
    html = %Q(<div class="hello" title={@title}>)
    result = AttributeHashExtractor.process(html)
    
    result.html.should eq html
    result.hashes.empty?.should be_true
  end
end
