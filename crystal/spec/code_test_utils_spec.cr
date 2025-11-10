require "spec"
require "./code_test_utils"
require "lexbor"

describe CodeTestUtils do

  it "trim_lines" do
    # string without newlines
    res_1 = CodeTestUtils.trim_lines("abc")
    res_1.should eq("abc")

    # string with leading/trailing whitespace on lines
    res_2 = CodeTestUtils.trim_lines("  abc  \n  def  \n  ghi  ")
    res_2.should eq("abc\ndef\nghi")

    # string with only whitespace lines
    res_3 = CodeTestUtils.trim_lines("  \n  \n  ")
    res_3.should eq("\n")

    # string with mixed content
    res_4 = CodeTestUtils.trim_lines("  hello  \nworld\n  test  ")
    res_4.should eq("hello\nworld\ntest")

    # empty string
    res_5 = CodeTestUtils.trim_lines("")
    res_5.should eq("")
  end

end
