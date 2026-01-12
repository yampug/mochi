{% begin %}
  @[Link(ldflags: "-L#{__DIR__}/../../../fragments/libs -ltree-sitter -Wl,-rpath,#{__DIR__}/../../../fragments/libs")]
  lib LibTreeSitter
    type Parser = Void*
    type Tree = Void*
    type Language = Void*

    struct TSNode
      context : UInt32[4]
      id : Void*
      tree : Tree
    end

    struct TSPoint
      row : UInt32
      column : UInt32
    end

    # Parser functions
    fun ts_parser_new : Parser
    fun ts_parser_delete(parser : Parser)
    fun ts_parser_set_language(parser : Parser, language : Language) : Bool
    fun ts_parser_parse_string(parser : Parser, old_tree : Tree, string : UInt8*, length : UInt32) : Tree

    # Tree functions
    fun ts_tree_root_node(tree : Tree) : TSNode
    fun ts_tree_delete(tree : Tree)

    # Node functions
    fun ts_node_type(node : TSNode) : UInt8*
    fun ts_node_is_null(node : TSNode) : Bool
    fun ts_node_child_count(node : TSNode) : UInt32
    fun ts_node_named_child_count(node : TSNode) : UInt32
    fun ts_node_child(node : TSNode, index : UInt32) : TSNode
    fun ts_node_named_child(node : TSNode, index : UInt32) : TSNode
    fun ts_node_child_by_field_name(node : TSNode, field_name : UInt8*, field_name_length : UInt32) : TSNode
    fun ts_node_start_byte(node : TSNode) : UInt32
    fun ts_node_end_byte(node : TSNode) : UInt32
    fun ts_node_start_point(node : TSNode) : TSPoint
    fun ts_node_end_point(node : TSNode) : TSPoint
    fun ts_node_string(node : TSNode) : UInt8*
  end

  # Ruby language binding
  @[Link(ldflags: "-L#{__DIR__}/../../../fragments/libs -ltree-sitter-ruby -Wl,-rpath,#{__DIR__}/../../../fragments/libs")]
  lib LibTreeSitterRuby
    fun tree_sitter_ruby : LibTreeSitter::Language
  end
{% end %}
