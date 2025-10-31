require "spec"
require "../../src/webcomponents/web_component_generator"
require "lexbor"
require "../spec_data_loader"

describe WebComponentGenerator do

  it "generate_bindings_code: simple" do
    bindings = {"abc" => "href"}
    exp_code = SpecDataLoader.load("bindings/bindings_simple.js")

    code = WebComponentGenerator.generate_bindings_code(bindings)
    code.should eq(exp_code)
  end

end
