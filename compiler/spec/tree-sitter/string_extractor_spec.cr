require "spec"
require "../spec_data_loader"
require "../../src/tree-sitter/string_extractor"
require "../../src/tree-sitter/method_body_extractor"
require "../../src/ruby/ruby_def"

def extract_string_from_method(rb_file : String, method_name : String) : String
  code = SpecDataLoader.load(rb_file)
  class_name = "TestComponent"
  methods = TreeSitter::MethodBodyExtractor.extract_method_bodies(code, class_name)
  ruby_def = methods[method_name]
  return TreeSitter::StringExtractor.extract_raw_string_from_def_body(ruby_def.body, method_name)
end

describe TreeSitter::StringExtractor do
  describe ".extract_raw_string_from_def_body" do
    it "extracts simple double-quoted strings" do
      result = extract_string_from_method("treesitter/string_extractor/double_quotes.rb", "html")
      result.should eq("<div>Hello</div>")
    end

    it "extracts simple single-quoted strings" do
      result = extract_string_from_method("treesitter/string_extractor/single_quotes.rb", "css")
      result.should eq("body { color: red; }")
    end

    it "handles %Q{} percent literals" do
      result = extract_string_from_method("treesitter/string_extractor/percent_q_uppercase.rb", "css")
      result.should contain(".component")
      result.should contain("color: blue;")
    end

    it "handles %q{} percent literals" do
      result = extract_string_from_method("treesitter/string_extractor/percent_q_lowercase.rb", "text")
      result.should eq("Simple text")
    end

    it "handles strings with escaped quotes" do
      result = extract_string_from_method("treesitter/string_extractor/escaped_quotes.rb", "html")
      result.should contain("data-value")
    end

    it "handles strings with quotes inside (not escaped)" do
      result = extract_string_from_method("treesitter/string_extractor/nested_quotes.rb", "html")
      result.should contain("class='highlighted'")
    end

    it "handles return statements with strings" do
      result = extract_string_from_method("treesitter/string_extractor/return_statement.rb", "html")
      result.should eq("<div>Content</div>")
    end

    it "handles reactables array string" do
      result = extract_string_from_method("treesitter/string_extractor/reactables_array.rb", "reactables")
      result.should eq("['count', 'name']")
    end
  end
end
