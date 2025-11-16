class InjectUtils

  def self.find_insertion_point(ruby_code : String, class_name : String, end_keyword : String, fallback_offset : Int32) : Int32?
    second_last_end = InjectUtils.find_second_last_end(ruby_code, end_keyword)

    unless second_last_end
      STDERR.puts "Warning: Could not find insertion point for methods in class #{class_name}"
      return nil
    end

    return InjectUtils.calculate_insertion_point(ruby_code, second_last_end, fallback_offset)
  end

  def self.find_second_last_end(text : String, end_keyword : String) : Int32?
    last_end = text.rindex(end_keyword)
    return nil unless last_end && last_end > 0

    return text.rindex(end_keyword, last_end - 1)
  end

  # calculate exact insertion point (after the line containing the end keyword)
  def self.calculate_insertion_point(code : String, end_position : Int32, fallback_offset : Int32) : Int32
    newline_after = code.index("\n", end_position)
    newline_after ? newline_after + 1 : end_position + fallback_offset
  end

  def self.insert_code(original : String, position : Int32, code_to_insert : String) : String
    return original[0...position] + code_to_insert + original[position..-1]
  end

end
