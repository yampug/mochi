require "spec"
require "lexbor"
require "diff"
require "../../src/webcomponents/web_component_generator"
require "../spec_data_loader"
require "../code_test_utils"

describe WebComponentGenerator do

  it "generate_bindings_code: simple" do
    bindings = {"abc" => "href"}
    exp_code = CodeTestUtils.trim_lines(
      SpecDataLoader.load("bindings/bindings_simple.js")
    )
    code = CodeTestUtils.trim_lines(
      WebComponentGenerator.generate_bindings_code(bindings)
    )
    code.should eq(exp_code)
  end

  it "generate_bindings_code: two" do
    bindings = {"abc" => "123", "def" => "5678"}
    exp_code = CodeTestUtils.trim_lines(
      SpecDataLoader.load("bindings/bindings_two.js")
    )
    code = CodeTestUtils.trim_lines(
      WebComponentGenerator.generate_bindings_code(bindings)
    )
    code.should eq(exp_code)
  end

  it "attr_changed_callback" do
    exp_code = CodeTestUtils.trim_lines(
      SpecDataLoader.load("bindings/attr_changed_callback.js")
    )
    code = CodeTestUtils.trim_lines(
      WebComponentGenerator.generate_attribute_changed_callback()
    )
    diff = Diff.new(code, exp_code.chomp, Diff::MyersLinear)
    code.should eq(exp_code)
  end

  it "generate_cond_eval_code: with conditions" do
    exp_code = CodeTestUtils.trim_lines(
      SpecDataLoader.load("bindings/cond_eval_code_simple.js")
    )
    block = ConditionalBlock.new(
      "@route == \"root\"",
      "\n      <p style=\"background: green; padding: 10px; border-radius: 8px;\">ROOT ROUTE</p>\n      <plus-five></plus-five>\n     ",
      45,
      193,
      66,
      0
    )
    conditionals = [block] of ConditionalBlock
    code = CodeTestUtils.trim_lines(
      WebComponentGenerator.generate_conditional_update_code(conditionals)
    )
    code.should eq(exp_code)
  end

  it "generate_cond_eval_code: no conditions" do
    conditionals = [] of ConditionalBlock
    code = CodeTestUtils.trim_lines(
      WebComponentGenerator.generate_conditional_update_code(conditionals)
    )
    code.should eq("")
  end

end
