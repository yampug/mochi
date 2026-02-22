class ConditionalResult
  property html : String
  property conditionals : Array(ConditionalBlock)

  def initialize(@html : String, @conditionals : Array(ConditionalBlock))
  end
end

class ConditionalMatch
  property condition : String
  property content_start : Int32

  def initialize(@condition : String, @content_start : Int32)
  end
end

class ConditionalBlock
  property condition : String
  property content : String
  property start_pos : Int32
  property end_pos : Int32
  property content_start_pos : Int32
  property id : Int32

  def initialize(@condition : String, @content : String, @start_pos : Int32, @end_pos : Int32, @content_start_pos : Int32, @id : Int32 = 0)
  end

  # check if another block is nested within this block
  def contains?(other : ConditionalBlock) : Bool
    other.start_pos > start_pos && other.end_pos < end_pos
  end

  def to_s (io : IO)
    io << "ConditionalBlock(condition: #{condition}, content: #{@content}, start_pos: #{start_pos}, end_pos: #{end_pos}, content_start_pos: #{content_start_pos}, id: #{id})"
  end
end

private struct StackFrame
  property condition : String
  property start_pos : Int32
  property content_start : Int32
  property id : Int32

  def initialize(@condition, @start_pos, @content_start, @id)
  end
end

class ConditionalProcessor
  IF_TOKEN      = "{if "
  END_TOKEN     = "{end}"
  IF_TOKEN_LEN  = 4
  END_TOKEN_LEN = 5

  # main entry point - processes HTML with {if}...{end} blocks
  def self.process(html : String) : ConditionalResult
    blocks = extract_conditionals(html)
    processed_html = replace_blocks_with_elements(html, blocks)
    ConditionalResult.new(processed_html, blocks)
  end

  # extract all conditional blocks from HTML using stack-based parsing
  def self.extract_conditionals(html : String) : Array(ConditionalBlock)
    blocks = [] of ConditionalBlock
    stack = [] of StackFrame
    next_id = 0
    pos = 0

    while pos < html.size
      if match = try_match_if_token(html, pos)
        stack << StackFrame.new(match.condition, pos, match.content_start, next_id)
        next_id += 1
        pos = match.content_start
      elsif try_match_end_token(html, pos)
        unless stack.empty?
          blocks << build_block_from_frame(stack.pop, html, pos)
        end
        pos += END_TOKEN_LEN
      else
        pos += 1
      end
    end

    blocks
  end

  # try to match {if ...} token at position
  def self.try_match_if_token(html : String, pos : Int32) : ConditionalMatch?
    return nil unless html[pos..].starts_with?(IF_TOKEN)

    close_brace = html.index("}", pos)
    return nil unless close_brace

    return ConditionalMatch.new(
      html[(pos + IF_TOKEN_LEN)...close_brace].strip,
      close_brace + 1,
    )
  end

  private def self.try_match_end_token(html : String, pos : Int32) : Bool
    html[pos..].starts_with?(END_TOKEN)
  end

  private def self.build_block_from_frame(frame : StackFrame, html : String, end_pos : Int32) : ConditionalBlock
    ConditionalBlock.new(
      condition: frame.condition,
      content: html[frame.content_start...end_pos],
      start_pos: frame.start_pos,
      end_pos: end_pos + END_TOKEN_LEN,
      content_start_pos: frame.content_start,
      id: frame.id
    )
  end

  # replace all blocks with <mochi-if> elements, processing from end to start
  # replace all blocks with <!--if-anchor--> elements
  private def self.replace_blocks_with_elements(html : String, blocks : Array(ConditionalBlock)) : String
    return html if blocks.empty?

    # Find top-level blocks only (blocks that are not contained by any other block)
    top_level_blocks = blocks.reject do |block|
      blocks.any? { |other| other != block && other.contains?(block) }
    end

    top_level_blocks.sort_by! { |b| -b.start_pos }
    
    result = html.dup
    top_level_blocks.each do |block|
      element = generate_element(block, blocks)
      result = result[0...block.start_pos] + element + result[block.end_pos..-1]
    end

    result
  end

  # generate comment anchor for a block
  private def self.generate_element(block : ConditionalBlock, all_blocks : Array(ConditionalBlock)) : String
    "<!--if-anchor-#{block.id}-->"
  end

  # process nested blocks within a parent block's content
  private def self.process_nested_blocks(block : ConditionalBlock, all_blocks : Array(ConditionalBlock)) : String
    nested = find_nested_blocks(block, all_blocks)
    return block.content if nested.empty?

    content = block.content
    nested.sort_by! { |b| -b.start_pos }

    nested.each do |nested_block|
      rel_start = nested_block.start_pos - block.content_start_pos
      rel_end = nested_block.end_pos - block.content_start_pos
      nested_element = generate_element(nested_block, all_blocks)
      content = replace_range(content, rel_start, rel_end, nested_element)
    end

    content
  end

  # find all blocks nested within the given block
  private def self.find_nested_blocks(block : ConditionalBlock, all_blocks : Array(ConditionalBlock)) : Array(ConditionalBlock)
    all_blocks.select { |b| block.contains?(b) }
  end
end
