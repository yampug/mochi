require "../html/each_processor"

class EachMethodGenerator
  METHOD_PREFIX = "__mochi_each_"
  END_KEYWORD   = "end"
  FALLBACK_OFFSET = 3

  def self.inject_methods_into_class(ruby_code : String, class_name : String, each_blocks : Array(EachBlock)) : String
    return ruby_code if each_blocks.empty?

    insertion_point = InjectUtils.find_insertion_point(ruby_code, class_name, END_KEYWORD, FALLBACK_OFFSET)
    return ruby_code unless insertion_point

    return ""
  end

  def self.generate_method(block : EachBlock, class_name : String) : String
    method_name_items = "#{METHOD_PREFIX}#{block.id}_items"
    method_name_key = "#{METHOD_PREFIX}#{block.id}_key"

    return <<-RUBY
      # auto-generated each method
      def #{method_name_items}
        return @items
      end

      def #{method_name_key}(item, index)
        return item.id
      end

    RUBY
  end


end
