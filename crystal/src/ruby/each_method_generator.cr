require "../html/each_processor"

class EachMethodGenerator
  METHOD_PREFIX = "__mochi_each_"
  END_KEYWORD   = "end"

  def self.generate_method(block : EachBlock, class_name : String) : String
    method_name = "#{METHOD_PREFIX}#{block.id}"

    return <<-RUBY
      # auto-generated each method
      def #{method_name}
        # TODO
      end
    RUBY
  end
end
