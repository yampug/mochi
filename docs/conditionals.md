# Conditional Rendering in Mochi

Mochi components support conditional rendering using `{if}...{end}` syntax directly in your HTML templates. Conditionals are **pre-compiled at build time** for maximum performance and full Ruby expression support.

## Table of Contents

- [Basic Usage](#basic-usage)
- [How It Works](#how-it-works)
- [Supported Expressions](#supported-expressions)
- [Nested Conditionals](#nested-conditionals)
- [Performance](#performance)
- [Examples](#examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Basic Usage

Use `{if}...{end}` blocks in your component's `html` method:

```ruby
class Counter
  @tag_name = "my-counter"
  @count

  def initialize
    @count = 0
  end

  def reactables
    ["count"]
  end

  def html
    %Q{
      <div>
        <h1>Count: {count}</h1>

        {if @count > 5}
          <p>Count is high!</p>
        {end}

        {if @count < 0}
          <p>Count is negative!</p>
        {end}

        <button on:click={increment}>Increment</button>
      </div>
    }
  end

  def css
    %Q{
      div { padding: 20px; }
    }
  end

  def increment
    @count += 1
  end
end
```

## How It Works

Mochi uses a unique **pre-compilation approach** for conditionals:

### Build Time (Crystal/Mochi Compiler)

1. **Extraction**: Mochi scans your HTML for `{if}...{end}` blocks
2. **ID Assignment**: Each conditional gets a unique ID (0, 1, 2...)
3. **Method Generation**: Ruby methods are generated for each conditional:
   ```ruby
   def __mochi_cond_0
     @count > 5
   end

   def __mochi_cond_1
     @count < 0
   end
   ```
4. **HTML Transformation**: Conditionals become `<mochi-if>` elements:
   ```html
   <mochi-if data-cond-id="0">
     <p>Count is high!</p>
   </mochi-if>
   ```
5. **Opal Transpilation**: Ruby methods are transpiled to JavaScript by Opal

### Runtime (Browser/JavaScript)

1. **Method Calls**: JavaScript calls the pre-compiled Opal methods:
   ```javascript
   let result = this.rubyComp.$__mochi_cond_0();
   ```
2. **Visibility**: Elements are shown/hidden based on the result:
   ```javascript
   condEl.style.display = result ? '' : 'none';
   ```

### Architecture Diagram

```
Ruby Component
     ↓
┌────────────────────────────────┐
│  ConditionalProcessor          │
│  - Extracts {if}...{end}       │
│  - Assigns IDs (0, 1, 2...)    │
│  - Creates <mochi-if> elements │
└────────────────────────────────┘
     ↓
┌────────────────────────────────┐
│  ConditionalMethodGenerator    │
│  - Generates Ruby methods      │
│  - def __mochi_cond_0          │
│  - def __mochi_cond_1          │
└────────────────────────────────┘
     ↓
┌────────────────────────────────┐
│  Opal Compiler                 │
│  - Transpiles to JavaScript    │
│  - $__mochi_cond_0(), etc.     │
└────────────────────────────────┘
     ↓
┌────────────────────────────────┐
│  WebComponent (Browser)        │
│  - Calls methods at runtime    │
│  - Shows/hides elements        │
└────────────────────────────────┘
```

## Supported Expressions

Mochi conditionals support **ALL Ruby expressions** because they're evaluated as actual Ruby code:

### Comparisons
```ruby
{if @count > 5}          # Greater than
{if @count >= 10}        # Greater than or equal
{if @count < 0}          # Less than
{if @count <= 100}       # Less than or equal
{if @value == "test"}    # Equality
{if @value != "test"}    # Inequality
```

### Boolean Logic
```ruby
{if @count > 5 && @enabled}           # AND
{if @count < 0 || @count > 100}       # OR
{if !@disabled}                        # NOT
{if @a && (@b || @c)}                 # Grouped logic
```

### Ruby Method Calls
```ruby
{if @items.empty?}                    # Check if array is empty
{if @user.nil?}                       # Check if value is nil
{if @hash.key?(:name)}                # Check hash key existence
{if @string.start_with?("Hello")}     # String methods
{if @array.include?(5)}               # Array methods
{if @number.even?}                    # Numeric predicates
```

### Complex Expressions
```ruby
{if @items.select { |i| i.active }.length > 0}
{if @users.find { |u| u.admin? }}
{if @value.to_i > 100 && @value.to_i < 200}
{if @data.fetch(:count, 0) > threshold}
```

### Instance Variables
```ruby
{if @count}              # Truthy check (any non-nil, non-false value)
{if @enabled}            # Boolean instance variable
{if @current_user}       # Object presence check
```

## Nested Conditionals

Conditionals can be nested to any depth:

```ruby
def html
  %Q{
    <div>
      {if @user}
        <div class="user-info">
          <h2>Welcome, {user.name}</h2>

          {if @user.admin?}
            <div class="admin-panel">
              <p>Admin Controls</p>

              {if @user.super_admin?}
                <button>Delete Everything</button>
              {end}
            </div>
          {end}

          {if @user.notifications.any?}
            <div class="notifications">
              <p>You have {user.notifications.count} notifications</p>
            </div>
          {end}
        </div>
      {end}
    </div>
  }
end
```

Each nested conditional gets its own unique ID and method:
- Outer: `__mochi_cond_0` → `@user`
- First nested: `__mochi_cond_1` → `@user.admin?`
- Second nested: `__mochi_cond_2` → `@user.super_admin?`
- Third nested: `__mochi_cond_3` → `@user.notifications.any?`

## Examples

### Show/Hide Based on State

```ruby
class TodoList
  @tag_name = "todo-list"
  @todos
  @show_completed

  def initialize
    @todos = []
    @show_completed = true
  end

  def reactables
    ["todos", "show_completed"]
  end

  def html
    %Q{
      <div class="todo-list">
        <h1>Todo List</h1>

        {if @todos.empty?}
          <p class="empty-state">No todos yet. Add one below!</p>
        {end}

        {if !@todos.empty?}
          <ul class="todos">
            <!-- Todo items here -->
          </ul>
        {end}

        {if @show_completed}
          <div class="completed-section">
            <!-- Completed todos -->
          </div>
        {end}

        <label>
          <input type="checkbox" on:change={toggle_completed}>
          Show completed
        </label>
      </div>
    }
  end

  def css
    %Q{
      .empty-state { color: gray; font-style: italic; }
      .todos { list-style: none; padding: 0; }
    }
  end

  def toggle_completed(e, checked)
    @show_completed = checked
  end
end
```

### Conditional Classes/Styles

```ruby
class StatusBadge
  @tag_name = "status-badge"
  @status  # "success", "warning", "error"

  def initialize
    @status = "success"
  end

  def reactables
    ["status"]
  end

  def html
    %Q{
      <div class="badge">
        {if @status == "success"}
          <span class="icon">[OK]</span>
        {end}

        {if @status == "warning"}
          <span class="icon">[!]</span>
        {end}

        {if @status == "error"}
          <span class="icon">[X]</span>
        {end}

        <span class="text">{status}</span>
      </div>
    }
  end

  def css
    %Q{
      .badge { display: flex; align-items: center; padding: 8px; }
      .icon { margin-right: 8px; }
    }
  end
end
```

### Loading States

```ruby
class DataFetcher
  @tag_name = "data-fetcher"
  @loading
  @error
  @data

  def initialize
    @loading = false
    @error = nil
    @data = nil
  end

  def reactables
    ["loading", "error", "data"]
  end

  def html
    %Q{
      <div>
        {if @loading}
          <div class="spinner">Loading...</div>
        {end}

        {if @error}
          <div class="error">
            <p>Error: {error}</p>
            <button on:click={retry}>Retry</button>
          </div>
        {end}

        {if @data && !@loading && !@error}
          <div class="content">
            <!-- Display data here -->
          </div>
        {end}
      </div>
    }
  end

  def css
    %Q{
      .spinner { color: blue; }
      .error { color: red; padding: 10px; }
    }
  end

  def retry
    fetch_data
  end
end
```

## Best Practices

### [DO] Best Practices

1. **Use Ruby Expressions Directly**
   ```ruby
   {if @items.empty?}        # [GOOD] Uses Ruby method
   {if @count > threshold}   # [GOOD] Uses Ruby variable/method
   ```

2. **Keep Conditions Simple**
   ```ruby
   # [GOOD] Clear intent
   {if @user.admin?}
     <button>Delete</button>
   {end}
   ```

3. **Use Helper Methods for Complex Logic**
   ```ruby
   def should_show_premium?
     @user && @user.subscription.active? && !@user.trial_expired?
   end

   def html
     %Q{
       {if should_show_premium?}
         <div class="premium-content">...</div>
       {end}
     }
   end
   ```

4. **Leverage Ruby's Truthiness**
   ```ruby
   {if @current_user}        # [GOOD] Checks for presence
   {if @items.any?}          # [GOOD] Checks for non-empty
   {if !@disabled}           # [GOOD] Boolean logic
   ```

### [AVOID] Anti-patterns

1. **Don't Repeat Complex Logic**
   ```ruby
   # [BAD] Duplicated logic
   {if @user && @user.premium? && @feature_enabled}
     ...
   {end}
   {if @user && @user.premium? && @feature_enabled}
     ...
   {end}

   # [GOOD] Extract to method
   def show_premium_feature?
     @user && @user.premium? && @feature_enabled
   end
   ```

2. **Don't Put Business Logic in Templates**
   ```ruby
   # [BAD] Complex calculation in template
   {if @items.map(&:price).sum > 1000}
     ...
   {end}

   # [GOOD] Move to method
   def total_over_threshold?
     total_price > 1000
   end

   def total_price
     @items.map(&:price).sum
   end
   ```

3. **Don't Use Side Effects in Conditions**
   ```ruby
   # [BAD] Modifying state in condition
   {if increment_counter}
     ...
   {end}

   # [GOOD] Pure predicate method
   {if counter_threshold_reached?}
     ...
   {end}
   ```

## Troubleshooting

### Conditional Not Working

**Problem**: Conditional doesn't show/hide as expected

**Solution**: Check that:
1. Instance variable is in `reactables` array
2. Condition syntax is valid Ruby
3. Method returns truthy/falsy value (not nil by accident)

```ruby
# [BAD] Variable not reactive
def reactables
  ["count"]  # Missing "enabled"
end

def html
  %Q{
    {if @enabled}  # Won't update!
      ...
    {end}
  }
end

# [GOOD] Variable is reactive
def reactables
  ["count", "enabled"]
end
```

### Nested Conditional Not Rendering

**Problem**: Nested conditional doesn't appear

**Solution**: Ensure parent conditional is true:

```ruby
{if @outer}
  <div>
    {if @inner}  # Only evaluated if @outer is true
      <p>Inner content</p>
    {end}
  </div>
{end}
```

### Method Not Defined Error

**Problem**: Browser console shows `$__mochi_cond_N is not a function`

**Solution**:
1. Rebuild your component (conditional methods may not have been generated)
2. Check that Opal transpilation completed successfully
3. Verify no syntax errors in your condition

### Complex Expression Fails

**Problem**: Complex Ruby expression doesn't work

**Solution**: Extract to a method:

```ruby
# If this doesn't work:
{if @items.select { |i| i.active }.count > 5}
  ...
{end}

# Try this:
def has_many_active_items?
  @items.select { |i| i.active }.count > 5
end

{if has_many_active_items?}
  ...
{end}
```

## Technical Details

### File Locations

- **Conditional Processing**: `crystal/src/html/conditional_processor.cr`
- **Method Generation**: `crystal/src/ruby/conditional_method_generator.cr`
- **JavaScript Generation**: `crystal/src/webcomponents/web_component_generator.cr`
- **Integration**: `crystal/src/mochi.cr`

### Test Files

- **Unit Tests**: `crystal/spec/conditional_processor_spec.cr`
- **Method Tests**: `crystal/spec/conditional_method_generator_spec.cr`
- **Integration Tests**: `crystal/spec/integration/conditional_integration_spec.cr`

### Generated Method Naming

Methods follow the pattern: `__mochi_cond_<ID>`

Where `<ID>` is a sequential integer starting from 0 for each component.

### HTML Attribute

Conditionals in rendered HTML use: `data-cond-id="<ID>"`

This ID corresponds to the generated method number.

## Future Enhancements

Potential improvements for future versions:

1. **else/elsif Support**
   ```ruby
   {if @count > 5}
     <p>High</p>
   {elsif @count > 0}
     <p>Medium</p>
   {else}
     <p>Low</p>
   {end}
   ```

2. **Conditional Caching**
   ```ruby
   # Cache result if condition doesn't depend on reactive state
   def __mochi_cond_0
     @__mochi_cond_0_cache ||= ENV["production"]
   end
   ```

3. **Debug Mode**
   ```ruby
   # Log condition evaluations in development
   {if @count > 5}  # Logs: "__mochi_cond_0: true (@count=10)"
     ...
   {end}
   ```