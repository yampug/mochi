  # auto-generated each method
  def __mochi_each_123_items
    return @items
  end

  def __mochi_each_123_key(item, index)
    # Use pure JavaScript to safely access id from both Ruby and JS objects
    `
      if (typeof #{item} === 'object' && #{item} !== null) {
        // Check for plain JS object with id property
        if (#{item}.id !== undefined && typeof #{item}.$id !== 'function') {
          return #{item}.id;
        }
        // Check for Ruby object with $id method
        if (typeof #{item}.$id === 'function') {
          try {
            return #{item}.$id();
          } catch(e) {
            // Fall through to index
          }
        }
      }
      return #{index};
    `
  end
