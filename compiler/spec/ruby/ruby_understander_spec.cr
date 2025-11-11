require "spec"
require "../spec_data_loader"
require "../../src/ruby/ruby_understander"

describe RubyUnderstander do
  it "processes simple if condition" do
    code = SpecDataLoader.load("ruby/a_layout.rb")
    name = RubyUnderstander.class_name(code)
    name.should eq("ALayout")
  end

end
