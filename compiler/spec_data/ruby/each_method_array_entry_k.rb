  # auto-generated each method
  def __mochi_each_123_items
    return @array
  end

  def __mochi_each_123_key(entry, k)
    # Use pure JavaScript to safely access id from both Ruby and JS objects
    `
      if (typeof #{entry} === 'object' && #{entry} !== null) {
        // Check for plain JS object with id property
        if (#{entry}.id !== undefined && typeof #{entry}.$id !== 'function') {
          return #{entry}.id;
        }
        // Check for Ruby object with $id method
        if (typeof #{entry}.$id === 'function') {
          try {
            return #{entry}.$id();
          } catch(e) {
            // Fall through to index
          }
        }
      }
      return #{k};
    `
  end
