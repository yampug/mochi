require "spec"
require "../../src/quickjs"

describe "Opal Compile Options" do
  it "generates module wrapper when file option is provided" do
    compiler = QuickJS::Opal::Compiler.new
    code = "puts 'hello'"

    res = compiler.compile(code, "lib/foo.rb", requirable: true)
    puts "Result with file: #{res}"


    res.should start_with("Opal.modules[\"lib/foo\"] =")

    res2 = compiler.compile("puts 1", "bar.rb", requirable: true)
    puts "Result with bar.rb: #{res2.lines.first}"

    compiler.finalize
  end
end
