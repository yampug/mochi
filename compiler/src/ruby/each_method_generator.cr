require "../html/each_processor"

class EachMethodGenerator
  METHOD_PREFIX = "__mochi_each_"
  END_KEYWORD   = "end"

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
