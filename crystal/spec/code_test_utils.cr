class CodeTestUtils

  def self.trim_lines(text : String) : String
    return text.split("\n").map(&.strip).join("\n")
  end
end
