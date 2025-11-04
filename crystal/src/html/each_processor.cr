class EachMatch
  property loop_def : EachLoopDef
  property content_start : Int32

  def initialize(@loop_def : EachLoopDef, @content_start : Int32)
  end
end

class EachBlock
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
    blocks = extract_each_blocks(html)
    # TODO

    return "abc"
  end

  def self.extract_each_blocks(html : String) : Array(EachBlock)
    result = [] of EachBlock
    pos = 0

    while pos < html.size
      if try_match_each_token(html, pos)
      # TODO
        elsif try_match_end_token(html, pos)
      # TODO
        else
        pos += 1
      end
    end
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

  def self.try_match_end_token(html : String, pos : Int32) : Boolean
    return html[pos..].starts_with?(END_TOKEN)
  end
end

