require "../../src/ruby/attribute_hash_generator"
require "../../src/html/attribute_hash_extractor"

describe AttributeHashGenerator do
  it "generates a method that serialized the truthy keys" do
    html = %Q(<div class={{ "nav-item" => true, "active" => @is_active }}>)
    extractor_result = AttributeHashExtractor.process(html)
    
    ruby_code = <<-RUBY
class MyComp
  def init
  end
end
RUBY

    amped_ruby = AttributeHashGenerator.inject_methods_into_class(ruby_code, "MyComp", extractor_result.hashes)
    
    amped_ruby.should contain("def __mochi_attr_hash_0")
    amped_ruby.should contain(%Q(_hash = {  "nav-item" => true, "active" => @is_active  }))
    amped_ruby.should contain(%Q(_hash.select { |k, v| v }.keys.join(" ")))
  end
end
