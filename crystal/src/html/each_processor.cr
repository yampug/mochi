class EachMatch
  property loop_def : EachLoopDef
  property content_start : Int32

  def initialize(@loop_def : EachLoopDef, @content_start : Int32)
  end
end

class EachBlock
  property loop_def : EachLoopDef
  property content : String
  property start_pos : Int32
  property end_pos : Int32
  property content_start_pos : Int32
  property id : Int32

  def initialize(@loop_def : EachLoopDef, @content : String, @start_pos : Int32, @end_pos : Int32, @content_start_pos : Int32, @id : Int32 = 0)
    end

  def contains?(other : EachBlock) : Bool
    other.start_pos > start_pos && other.end_pos < end_pos
  end

  def to_s (io : IO)
    io << "EachBlock(loop_def: #{loop_def}, content: #{@content}, start_pos: #{start_pos}, end_pos: #{end_pos}, content_start_pos: #{content_start_pos}, id: #{id})"
  end
end

private struct EachStackFrame
  property loop_def : EachLoopDef
  property start_pos : Int32
  property content_start : Int32
  property id : Int32

  def initialize(@loop_def, @start_pos, @content_start, @id)
  end
end

class EachLoopDef
  property array_name : String
  property item_name : String
  property index_name : String?

  def initialize(@array_name : String, @item_name : String, @index_name : String?)
  end
end

class EachProcessor
  EACH_TOKEN    = "{each "
  END_TOKEN     = "{end}"
  EACH_TOKEN_LEN  = 6
  END_TOKEN_LEN = 5

  def self.process(html : String) : String
    all_blocks = extract_each_blocks(html)
    # TODO

    return "abc"
  end

  def self.replace_blocks_with_elements(html : String, all_blocks : Array(EachBlock)) : String
    return html if all_blocks.empty?

    result = html.dup
    all_blocks.sort_by! { |b| -b.start_pos }

    all_blocks.each do |block|
      element = generate_element(block, all_blocks)
      result = replace_range(result, block.start_pos, block.end_pos, element)
    end

    return result
  end

  def self.replace_range(str : String, start_pos : Int32, end_pos : Int32, replacement : String) : String
    return str[0...start_pos] + replacement + str[end_pos..-1]
  end

  def self.generate_element(block : EachBlock, all_blocks : Array(EachBlock)) : String
    content = process_nested_blocks(block, all_blocks)
    return %Q{<mochi-each data-loop-id="#{block.id}">#{content}</mochi-each>}
  end

  private def self.process_nested_blocks(block : EachBlock, all_blocks : Array(EachBlock)) : String
    nested = all_blocks.select { |b| block.contains?(b) }
    return block.content if nested.empty?

    content = block.content
    nested.sort_by! { |b| -b.start_pos }

    nested.each do |nested_block|
      rel_start = nested_block.start_pos - block.content_start_pos
      rel_end = nested_block.end_pos - block.content_start_pos
      nested_element = generate_element(nested_block, all_blocks)
      content = replace_range(content, rel_start, rel_end, nested_element)
    end

    return content
  end

  def self.extract_each_blocks(html : String) : Array(EachBlock)
    result = [] of EachBlock
    stack = [] of EachStackFrame
    next_id = 0
    pos = 0

    while pos < html.size
      if match = try_match_each_token(html, pos)
          stack << EachStackFrame.new(match.loop_def, pos, match.content_start, next_id)
          next_id += 1
          pos = match.content_start
        elsif try_match_end_token(html, pos)
          unless stack.empty?
            frame = stack.pop
            result << EachBlock.new(
              loop_def: frame.loop_def,
              content: html[frame.content_start...pos],
              start_pos: frame.start_pos,
              end_pos: pos + END_TOKEN_LEN,
              content_start_pos: frame.content_start,
              id: frame.id
            )
          end
          pos += END_TOKEN_LEN
        else
        pos += 1
      end
    end
    return result
  end

  def self.try_match_each_token(html : String, pos : Int32) : EachMatch?
    return nil unless html[pos..].starts_with?(EACH_TOKEN)

    close_brace = html.index("}", pos)
    return nil unless close_brace

    loop_str = html[(pos + EACH_TOKEN_LEN)...close_brace].strip
    loop_def = extract_loop_definition(loop_str)
    if loop_def
      return EachMatch.new(loop_def, close_brace + 1)
    end
    return nil
  end

  def self.extract_loop_definition(loop_str : String) : EachLoopDef?
    parts = loop_str.split(" as ")
    if parts.size == 2
      if parts[1].includes?(",")
        item_parts = parts[1].split(",")
        return EachLoopDef.new(parts[0], item_parts[0].strip, item_parts[1].strip)
      else
        return EachLoopDef.new(parts[0], parts[1], nil)
      end
    end
    return nil
  end

  def self.try_match_end_token(html : String, pos : Int32) : Bool
    return html[pos..].starts_with?(END_TOKEN)
  end
end

