require "spec"
require "../spec_data_loader"
require "../../src/tree-sitter/imports_extractor"

def get_imports(rb_file : String) : Array(String)
  code = SpecDataLoader.load(rb_file)
  TreeSitter::ImportsExtractor.extract_imports(code)
end

describe TreeSitter::ImportsExtractor do

  it "extracts simple require statements with double quotes" do
    imports = get_imports("ruby/imports_simple.rb")
    imports.should eq ["json", "file_utils"]
  end

  it "extracts require statements with single quotes" do
    imports = get_imports("ruby/imports_single_quotes.rb")
    imports.should eq ["json", "file_utils"]
  end

  it "extracts mixed quote styles" do
    imports = get_imports("ruby/imports_mixed.rb")
    imports.should eq ["json", "file_utils", "http/client"]
  end

  it "extracts relative path requires" do
    imports = get_imports("ruby/imports_relative.rb")
    imports.should eq ["./lib/helper", "../utils/parser"]
  end

  it "returns empty array when no requires" do
    imports = get_imports("ruby/imports_none.rb")
    imports.should eq [] of String
  end

  it "ignores commented out requires" do
    imports = get_imports("ruby/imports_with_comments.rb")
    imports.should eq ["json", "file_utils"]
  end

  it "handles indented requires" do
    imports = get_imports("ruby/imports_indented.rb")
    imports.should eq ["json", "file_utils"]
  end

end
