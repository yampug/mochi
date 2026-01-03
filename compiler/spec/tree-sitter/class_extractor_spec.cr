require "spec"
require "../spec_data_loader"
require "../../src/tree-sitter/class_extractor"

def get_class_names(rb_file : String) : Array(String)
  code = SpecDataLoader.load(rb_file)
  puts "code:#{code}"
  names = TreeSitter::ClassExtractor.extract_class_names(code)
  puts "Extracted names: '#{names}'"
  return names
end

def get_class_name(rb_file : String) : String
  code = SpecDataLoader.load(rb_file)
  puts "code:#{code}"
  name = TreeSitter::ClassExtractor.class_name(code)
  puts "Extracted name: '#{name}'"
  return name
end

describe TreeSitter::ClassExtractor do

  it "extracts simple class name" do
    name = get_class_name("treesitter/class_name_simple.rb")
    name.should eq "MyClass"
  end

  it "extracts class name with inheritance" do
    name = get_class_name("treesitter/class_name_with_inheritance.rb")
    name.should eq "MyClass"
  end

  it "extracts namespaced class name" do
    name = get_class_name("treesitter/class_name_namespaced.rb")
    name.should eq "My::Nested::Class"
  end

  it "extracts all class names from file with multiple classes" do
    names = get_class_names("treesitter/class_name_multi_classes.rb")
    names.should eq ["FirstClass", "SecondClass", "ThirdClass"]
  end

end
