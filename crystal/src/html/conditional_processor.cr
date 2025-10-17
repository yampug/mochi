class ConditionalResult
  property html : String
  property conditionals : Array(ConditionalBlock)

  def initialize(@html : String, @conditionals : Array(ConditionalBlock))
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
end

# Internal struct for parsing state (not exposed publicly)
private struct StackFrame
  property condition : String
  property start_pos : Int32
  property content_start : Int32
  property id : Int32

  def initialize(@condition, @start_pos, @content_start, @id)
  end
end

class ConditionalProcessor
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
      # check for {if ...}
      if html[pos..].starts_with?("{if ")
        if close_brace = html.index("}", pos)
          condition = html[(pos + 4)...close_brace].strip
          stack << StackFrame.new(condition, pos, close_brace + 1, next_id)
          next_id += 1
          pos = close_brace + 1
          next
        end
      end

      # check for {end}
      if html[pos..].starts_with?("{end}")
        unless stack.empty?
          frame = stack.pop
          blocks << ConditionalBlock.new(
            condition: frame.condition,
            content: html[frame.content_start...pos],
            start_pos: frame.start_pos,
            end_pos: pos + 5,
            content_start_pos: frame.content_start,
            id: frame.id
          )
        end
        pos += 5
        next
      end

      pos += 1
    end

    blocks
  end

  # replace all blocks with <mochi-if> elements, processing from end to start
  private def self.replace_blocks_with_elements(html : String, blocks : Array(ConditionalBlock)) : String
    result = html.dup

    # sort blocks by position (reverse order to preserve indices)
    blocks.sort_by! { |b| -b.start_pos }

    blocks.each do |block|
      # generate replacement element
      element = generate_element(block, blocks)
      result = result[0...block.start_pos] + element + result[block.end_pos..-1]
    end

    result
  end

  # generate <mochi-if> element for a block, handling nested blocks
  private def self.generate_element(block : ConditionalBlock, all_blocks : Array(ConditionalBlock)) : String
    content = block.content

    # find and process nested blocks
    nested = all_blocks.select { |b| b.start_pos > block.start_pos && b.end_pos < block.end_pos }

    unless nested.empty?
      nested.sort_by! { |b| -b.start_pos }

      nested.each do |nested_block|
        # calculate relative positions within this block's content
        rel_start = nested_block.start_pos - block.content_start_pos
        rel_end = nested_block.end_pos - block.content_start_pos

        nested_element = generate_element(nested_block, all_blocks)
        content = content[0...rel_start] + nested_element + content[rel_end..-1]
      end
    end

    %Q{<mochi-if data-cond-id="#{block.id}">#{content}</mochi-if>}
  end
end
