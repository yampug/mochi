require "spec"
require "../spec_data_loader"
require "../../src/ruby/each_method_generator"

describe EachMethodGenerator do
  it "generate_method - no index" do
    exp_code = SpecDataLoader.load("ruby/each_generated_method_a.rb")
    loop_def : EachLoopDef = EachProcessor.extract_loop_definition("@items as item").not_nil!
    block = EachBlock.new(
      loop_def,
      "<li>{item.name}</li>",
      0,
      56,
      31,
      123
    )
    ruby_code = EachMethodGenerator.generate_method(block, "abc")
    ruby_code.should eq(exp_code)
  end

  it "generate_method - with index" do
    exp_code = SpecDataLoader.load("ruby/each_generated_method_a.rb")
    loop_def : EachLoopDef = EachProcessor.extract_loop_definition("@array as entry, k").not_nil!
    block = EachBlock.new(
      loop_def,
      "<li>{entry.name}</li>",
      0,
      56,
      31,
      123
    )
    ruby_code = EachMethodGenerator.generate_method(block, "abc")
    ruby_code.should eq(exp_code)
  end
end
