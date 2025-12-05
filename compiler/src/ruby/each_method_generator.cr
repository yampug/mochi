require "../html/each_processor"
require "./inject_utils"

class EachMethodGenerator
  METHOD_PREFIX = "__mochi_each_"
  END_KEYWORD   = "end"
  FALLBACK_OFFSET = 3

  def self.inject_methods_into_class(ruby_code : String, class_name : String, each_blocks : Array(EachBlock)) : String
    return ruby_code if each_blocks.empty?

    insertion_point = InjectUtils.find_insertion_point(ruby_code, class_name, END_KEYWORD, FALLBACK_OFFSET)
    return ruby_code unless insertion_point

    methods_code = generate_all_methods(each_blocks, class_name)
    return InjectUtils.insert_code(ruby_code, insertion_point, methods_code)
  end

  def self.generate_all_methods(each_blocks : Array(EachBlock), class_name : String) : String
    each_blocks.map { |block|
      generate_method(block, class_name)
    }.join("\n")
  end

  def self.generate_method(block : EachBlock, class_name : String) : String
    method_name_items = "#{METHOD_PREFIX}#{block.id}_items"
    method_name_key = "#{METHOD_PREFIX}#{block.id}_key"
    array_name = block.loop_def.array_name
    item_name = block.loop_def.item_name
    index_name = block.loop_def.index_name || "index"

    return <<-RUBY
      # auto-generated each method
      def #{method_name_items}
        return #{array_name}
      end

      def #{method_name_key}(#{item_name}, #{index_name})
        # Use pure JavaScript to safely access id from both Ruby and JS objects
        `
          if (typeof #\{#{item_name}} === 'object' && #\{#{item_name}} !== null) {
            // Check for plain JS object with id property
            if (#\{#{item_name}}.id !== undefined && typeof #\{#{item_name}}.$id !== 'function') {
              return #\{#{item_name}}.id;
            }
            // Check for Ruby object with $id method
            if (typeof #\{#{item_name}}.$id === 'function') {
              try {
                return #\{#{item_name}}.$id();
              } catch(e) {
                // Fall through to index
              }
            }
          }
          return #\{#{index_name}};
        `
      end

    RUBY
  end


end
