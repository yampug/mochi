require "spec"
require "../spec_data_loader"
require "../../src/ruby/ruby_understander"

def check_class_name(exp_name : String, code : String)
  name = RubyUnderstander.class_name(code)
  name.should eq(exp_name)
end

describe RubyUnderstander do

  it "processes simple if condition" do
    code = SpecDataLoader.load("ruby/a_layout.rb")
    name = RubyUnderstander.class_name(code)
    name.should eq("ALayout")
  end

  it "class_name: inheritance" do
    check_class_name("MyClass", "class MyClass < ParentClass")
  end

  it "class_name: namespacing" do
    check_class_name("My::Nested::Class", "class My::Nested::Class")
  end

  it "class_name: extra spaces" do
    check_class_name("MyClass", "class   MyClass   ;   end")
  end

  it "class_name: comments" do
    check_class_name("MyClass", "class MyClass # comment")
  end

  it "class_name: embedded string" do
    check_class_name("", "\"class NotAClass\"")
  end

  it "class_name: class in a comment" do
    check_class_name("", "# class InComment ")
  end

  it "class_name: nested class" do
    check_class_name("A", "class A; class B; end; end")
  end

end
