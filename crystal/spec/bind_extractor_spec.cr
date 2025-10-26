require "spec"
require "../src/bind_extractor"
require "lexbor"

describe BindExtractor do
    it "does something cool" do
        puts "magic"
        result = BindExtractor.extract("<a bind:href='abc'></a>")
      puts result
      result.html.should eq("<a href=\"abc\"></a>")
      result.bindings.should eq({"b" => "href"})
    end
end
