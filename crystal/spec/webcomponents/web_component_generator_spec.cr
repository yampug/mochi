require "spec"
require "../../src/webcomponents/web_component_generator"
require "lexbor"

describe WebComponentGenerator do

  it "generate_bindings_code: simple" do
    bindings = {"abc" => "href"}
    exp_code = File.read("./spec_data/bindings/bindings_simple.js")

    code = WebComponentGenerator.generate_bindings_code(bindings)
    code.should eq(exp_code)
  end

end
