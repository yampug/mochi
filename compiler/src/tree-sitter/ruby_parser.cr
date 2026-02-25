require "./bindings"

module TreeSitter
  class Node
    getter raw : LibTreeSitter::TSNode
    getter source : String

    def initialize(@raw : LibTreeSitter::TSNode, @source : String)
      end

    def type : String
      ptr = LibTreeSitter.ts_node_type(@raw)
      String.new(ptr)
    end

    def null? : Bool
      LibTreeSitter.ts_node_is_null(@raw)
    end

    def child_count : Int32
      LibTreeSitter.ts_node_child_count(@raw).to_i
    end

    def named_child_count : Int32
      LibTreeSitter.ts_node_named_child_count(@raw).to_i
    end

    def child(index : Int32) : Node
      raw_child = LibTreeSitter.ts_node_child(@raw, index.to_u32)
      Node.new(raw_child, @source)
    end

    def named_child(index : Int32) : Node
      raw_child = LibTreeSitter.ts_node_named_child(@raw, index.to_u32)
      Node.new(raw_child, @source)
    end

    def child_by_field_name(field_name : String) : Node?
      raw_child = LibTreeSitter.ts_node_child_by_field_name(
      @raw,
      field_name.to_unsafe,
      field_name.bytesize.to_u32
      )
        return nil if LibTreeSitter.ts_node_is_null(raw_child)
      Node.new(raw_child, @source)
    end

    def text : String
      start_byte = LibTreeSitter.ts_node_start_byte(@raw)
      end_byte = LibTreeSitter.ts_node_end_byte(@raw)
      @source.byte_slice(start_byte, end_byte - start_byte)
    end

    def to_s(io : IO)
      ptr = LibTreeSitter.ts_node_string(@raw)
      str = String.new(ptr)
      io << str
      LibC.free(ptr)
    end

    def each_child(&block : Node ->)
      child_count.times do |i|
        yield child(i)
      end
    end

    def each_named_child(&block : Node ->)
      named_child_count.times do |i|
        yield named_child(i)
      end
    end
  end

  class RubyParser
    @parser : LibTreeSitter::Parser

    def initialize
      @parser = LibTreeSitter.ts_parser_new
      language = LibTreeSitterRuby.tree_sitter_ruby
      success = LibTreeSitter.ts_parser_set_language(@parser, language)
        raise "Failed to set Ruby language" unless success
    end

    def parse(source : String) : Tree
      tree_ptr = LibTreeSitter.ts_parser_parse_string(
      @parser,
      nil,
      source.to_unsafe,
      source.bytesize.to_u32
      )
      Tree.new(tree_ptr, source)
    end

    def finalize
      LibTreeSitter.ts_parser_delete(@parser)
    end
  end

  class Tree
    @tree : LibTreeSitter::Tree
    @source : String

    def initialize(@tree : LibTreeSitter::Tree, @source : String)
      end

    def root_node : Node
      raw_node = LibTreeSitter.ts_tree_root_node(@tree)
      Node.new(raw_node, @source)
    end

    def finalize
      LibTreeSitter.ts_tree_delete(@tree)
    end
  end
end
