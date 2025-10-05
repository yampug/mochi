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

  def initialize(@condition : String, @content : String, @start_pos : Int32, @end_pos : Int32)
  end
end

class ConditionalProcessor

  # Main entry point - processes HTML with {if}...{end} blocks
  def self.process(html : String) : ConditionalResult
    conditionals = [] of ConditionalBlock
    processed_html = html.dup

    # Process conditionals from end to start to maintain position indices
    blocks = extract_conditionals(html)

    # Sort by start position in reverse order
    blocks.sort_by! { |b| -b.start_pos }

    blocks.each do |block|
      replacement = generate_mochi_if_element(block)
      processed_html = processed_html[0...block.start_pos] + replacement + processed_html[block.end_pos..-1]
    end

    ConditionalResult.new(processed_html, blocks)
  end

  def self.extract_conditionals(html : String) : Array(ConditionalBlock)
    blocks = [] of ConditionalBlock
    stack = [] of Hash(String, Int32 | String)
    i = 0

    while i < html.size
      if html[i..].starts_with?("{if ")
        close_brace = html.index("}", i)
        if close_brace
          condition_start = i + 4 # skip "{if "
          condition = html[condition_start...close_brace].strip

          # push to stack
          stack << {
            "condition" => condition,
            "start_pos" => i,
            "content_start" => close_brace + 1
          } of String => (Int32 | String)

          i = close_brace + 1
          next
        end
      end

      # look for {end}
      if html[i..].starts_with?("{end}")
        if stack.size > 0
          block_info = stack.pop
          condition = block_info["condition"].as(String)
          start_pos = block_info["start_pos"].as(Int32)
          content_start = block_info["content_start"].as(Int32)

          # extract content between {if} and {end}
          content = html[content_start...i].strip
          end_pos = i + 5 # include "{end}"

          blocks << ConditionalBlock.new(
            condition: condition,
            content: content,
            start_pos: start_pos,
            end_pos: end_pos
          )
        end

        i += 5 # skip "{end}"
        next
      end

      i += 1
    end

    blocks
  end

  private def self.generate_mochi_if_element(block : ConditionalBlock) : String
    # escape the condition for HTML attribute
    escaped_condition = block.condition
      .gsub("&", "&amp;")
      .gsub("\"", "&quot;")
      .gsub("<", "&lt;")
      .gsub(">", "&gt;")

    processed_content = block.content
    nested_blocks = extract_conditionals(processed_content)

    if nested_blocks.size > 0
      nested_blocks.sort_by! { |b| -b.start_pos }

      nested_blocks.each do |nested_block|
        replacement = generate_mochi_if_element(nested_block)
        processed_content = processed_content[0...nested_block.start_pos] + replacement + processed_content[nested_block.end_pos..-1]
      end
    end

    %Q{<mochi-if data-condition="#{escaped_condition}">#{processed_content}</mochi-if>}
  end
end
