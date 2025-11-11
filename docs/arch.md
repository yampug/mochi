# Mochi Framework Architecture Summary

## Overview

Mochi is a framework that brings type-safe Ruby to the web by leveraging:
- **Opal**: Compiles Ruby to JavaScript
- **Web Components**: HTML standard custom elements
- **Crystal**: Compiler/build system
- **Sorbet**: Optional type checking

The framework enables developers to write Ruby components that compile to Web Components with full reactivity and event handling.

---

## 1. Component Definition & Structure

### Basic Component Template

Every Mochi component follows this structure:

```ruby
class MyComponent
  @tag_name = "my-component"      # Required: HTML tag name
  @my_prop                         # Instance variables = reactive state
  
  def initialize
    @my_prop = "initial value"
  end
  
  def reactables
    ["my_prop"]                    # Declares which vars trigger re-renders
  end
  
  def html
    %Q{
      <div>
        <h1>{my_prop}</h1>
        <button on:click={handle_click}>Click Me</button>
      </div>
    }
  end
  
  def css
    %Q{
      h1 { color: blue; }
    }
  end
  
  def handle_click
    @my_prop = "clicked!"
  end
  
  def mounted(shadow_root, component)
    puts "Component mounted"
  end
  
  def unmounted
    puts "Component unmounted"
  end
end
```

### Key Component Requirements

1. **@tag_name**: Must be set as class variable, defines the custom element name (kebab-case)
2. **@properties**: Instance variables become the component state
3. **reactables()**: Returns array of property names that trigger re-renders
4. **html()**: Returns HTML template with placeholder syntax
5. **css()**: Returns scoped styles (added to Shadow DOM)
6. **Lifecycle hooks**: `mounted()` and `unmounted()` for setup/cleanup

### Key Characteristics

- **Single File**: Ruby class = one Web Component
- **Reactive by Default**: Declare which properties are reactive via `reactables`
- **Scoped Styling**: CSS is automatically scoped to component's Shadow DOM
- **No Props API**: Components use class variables instead of props

---

## 2. Attributes & Props Handling

### Overview

Mochi uses a **two-way binding system** with `bind:` directives and attribute synchronization.

### Event Handlers (on:click, on:change)

#### Syntax
```ruby
def html
  %Q{
    <button on:click={method_name}>Click</button>
    <input on:change={handler_method} type="text"></input>
  }
end
```

#### How It Works

1. **HTML Processing**: `on:click={methodName}` → `on:click="{methodName}"`
2. **JavaScript Runtime**: 
   - Attaches click listeners to `[on\\:click]` elements
   - Extracts method name from attribute value
   - Calls Ruby method: `this.rubyComp["$methodName"]()`
   - Triggers `syncAttributes()` and `render()` after execution

3. **Change Events**: Similar flow but passes event + value
   - Automatically converts numeric strings to numbers
   - Example: `on:change={input_changed}` with `def input_changed(e, value)`

#### Generated JavaScript Pattern
```javascript
// In web component's render method
this.shadow.addEventListener('click', (event) => {
  const clickedElement = event.target;
  const actionTarget = clickedElement.closest('[on\\:click]');
  if (actionTarget) {
    let actionValue = actionTarget.getAttribute('on:click');
    let trimmedActionVal = actionValue.substring(1, actionValue.length - 1);
    this.rubyComp["$"+trimmedActionVal]()  // Call Ruby method
    this.syncAttributes();
    this.render();
  }
});
```

### Binding with child Components (bind:)

#### Syntax
```ruby
# Parent component
def html
  %Q{
    <child-component bind:count="{my_count}"></child-component>
  }
end

# Child component
class ChildComponent
  @tag_name = "child-component"
  @count
  
  def reactables
    ["count"]
  end
end
```

#### How It Works

1. **Extraction**: `BindExtractor` parses HTML for `bind:` attributes
2. **Processing**: 
   - Removes `bind:` prefix
   - Creates mapping: `{my_count}` → `count` attribute
   - Uses `MutationObserver` to watch attribute changes
3. **Synchronization**: 
   - When parent updates `@my_count`, attribute changes on child element
   - MutationObserver detects change
   - Calls `attributeChangedCallback` on child component
   - Child's setter is invoked: `child.rubyComp.set_count(newValue)`
   - Child re-renders

#### BindExtractor Process
```crystal
# File: compiler/src/bind_extractor.cr
# 1. Parses HTML with lexbor
# 2. Finds all bind: attributes
# 3. Extracts the property name from {bracketed} values
# 4. Creates mapping hash
# 5. Returns cleaned HTML + bindings map
```

---

## 3. Rendering Pipeline & Lifecycle

### Compilation Flow

```
Ruby Component File
        ↓
[Crystal Transpiler - compiler/src/mochi.cr]
        ↓
1. Extract class name, methods, imports
2. Parse HTML template
3. Process conditionals ({if}...{end})
4. Extract bindings (bind:)
5. Generate getter/setter methods
6. Create Web Component class (JavaScript)
7. Transpile Ruby → JavaScript (Opal)
        ↓
Output: components.js
```

### Detailed Transpilation Steps

#### Step 1: Component Analysis
```crystal
# RubyUnderstander extracts:
- Class name
- Method bodies (html, css, reactables, etc.)
- Instance variables
- Imports
- @tag_name
```

#### Step 2: Conditional Processing
```crystal
# ConditionalProcessor converts:
{if @count > 5}
  <p>High</p>
{end}
        ↓
<mochi-if data-cond-id="0">
  <p>High</p>
</mochi-if>

# Generates Ruby methods:
def __mochi_cond_0
  @count > 5
end
```

#### Step 3: Binding Extraction
```crystal
# BindExtractor converts:
<child bind:pfcount="{count}"></child>
        ↓
<child pfcount="{count}"></child>
# + bindings map: {"count" => "pfcount"}
```

#### Step 4: Augment Ruby Code
```crystal
# Add generated methods and getters/setters to original Ruby
# For each reactable property, generate:

def get_count
  @count
end

def set_count(value)
  @count = value
end

# Plus conditional methods:
def __mochi_cond_0
  @count > 5
end
```

#### Step 5: Generate Web Component JavaScript
```javascript
class MyComponentWebComp extends HTMLElement {
  constructor() {
    super();
    this.rubyComp = Opal.MyComponent.$new();  // Create Ruby instance
    this.paintCount = 0;
  }
  
  connectedCallback() {
    this.shadow = this.attachShadow({ mode: "open" });
    this.render();
    this.rubyComp.$mounted(this.shadow, this);  // Call Ruby mounted()
  }
  
  render() {
    // Template with {placeholder} syntax
    let html = `<h1>Count: {count}</h1>...`;
    
    // Replace placeholders with getter values
    for (let i = 0; i < reactablesArr.length; i++) {
      let varName = reactablesArr[i];
      html = html.replaceAll("{" + varName + "}", 
        this.rubyComp["$get_" + varName]());
    }
    
    // Evaluate conditionals
    let conditionalElements = this.shadow.querySelectorAll('mochi-if');
    for (let condEl of conditionalElements) {
      let condId = parseInt(condEl.getAttribute('data-cond-id'));
      let result = this.evaluateCondition(condId);
      condEl.style.display = result ? '' : 'none';
    }
    
    this.shadow.innerHTML = html;
    // ... attach event listeners ...
  }
  
  evaluateCondition(condId) {
    try {
      let methodName = `$__mochi_cond_${condId}`;
      let result = this.rubyComp[methodName]();
      return result !== false && result !== Opal.nil;
    } catch (e) {
      console.error('Error in conditional', e);
      return false;
    }
  }
  
  disconnectedCallback() {
    this.rubyComp.$unmounted();  // Call Ruby unmounted()
  }
  
  static get observedAttributes() {
    return reactablesArr;
  }
  
  attributeChangedCallback(name, oldValue, newValue) {
    // Update instance variable
    this.rubyComp["$set_" + name](newValue);
    this.render();
  }
}

customElements.define("my-component", MyComponentWebComp);
```

#### Step 6: Opal Transpilation
```bash
opal -I ./lib \
     -cO \
     -s opal -s native -s promise -s browser/setup/full -s sorbet-runtime \
     ./lib/Root.rb \
     -o components.js
```

All Ruby components + generated methods are transpiled to JavaScript.

### Runtime Lifecycle

```
1. Component HTML in DOM
   <my-component></my-component>

2. Browser creates custom element instance
   → constructor() called
   → Opal.MyComponent.$new() creates Ruby instance
   → Initialize Ruby instance variables

3. Element inserted into DOM
   → connectedCallback() triggered
   → Shadow DOM created
   → render() called (first render)
   → Ruby mounted() hook called

4. User interaction
   → Click/change event on element
   → Event listener calls Ruby method
   → Instance variables updated
   → syncAttributes() called (updates HTML attributes)
   → render() called again
   → Conditionals re-evaluated
   → Shadow DOM innerHTML updated
   → HTML placeholders replaced with new values

5. Component removed from DOM
   → disconnectedCallback() triggered
   → Ruby unmounted() hook called
```

---

## 4. Existing Navigation/Routing

### Router Class

Located in: `/Users/bob/repos/mochi/compiler/build/src/lib/mochi.rb`

```ruby
class AppRouter
  def initialize(&block)
    @routes = []
    instance_eval(&block) if block_given?
  end

  def on(path_pattern, &handler)
    names, regex = compile_path(path_pattern)
    @routes << { names: names, regex: regex, handler: handler }
  end

  def not_found(&handler)
    @not_found_handler = handler
  end

  # Compiles /users/:id/posts/:post_id into regex with capture groups
  def compile_path(path_pattern)
    names = []
    regex_string = path_pattern.gsub(/:\w+/) do |match|
      names << match.tr(':', '')
      '([^\/]+)'
    end
    [names, Regexp.new("^#{regex_string}$")]
  end

  # Resolve from current browser location
  def resolve
    path = `window.location.pathname`
    query_params = `window.location.search`
    resolve_manual(path, query_params)
  end

  # Resolve specific path (useful for testing)
  def resolve_manual(path, query_params)
    @routes.each do |route|
      match_data = path.match(route[:regex])
      if match_data
        params = Hash[route[:names].zip(match_data.captures)]
        return route[:handler].call(params)
      end
    end
    @not_found_handler.call if @not_found_handler
  end
end
```

### Example Usage (router_demo.rb)

```ruby
def mounted(shadow_root, comp)
  router = AppRouter.new do
    on '/' do
      puts "Home page"
      `#{comp}.rubyComp.route = "root"`
      `#{comp}.syncAttributes()`
    end

    on '/users/:id/posts/:post_id' do |params|
      puts "User: #{params['id']}, Post: #{params['post_id']}"
    end

    not_found do
      puts "404 - Not found"
    end
  end
  
  router.resolve  # Match current browser location
end
```

### Limitations of Current Router

- Routes are resolved in `mounted()` lifecycle hook
- Manual state updates required: `comp.rubyComp.route = "root"`
- No built-in route change detection
- No component swapping based on routes
- Would need nested components for different route views

---

## 5. Nested Components & Children

### Current Pattern for Nested Components

#### Using Composition

```ruby
# Parent component
class ParentComponent
  @tag_name = "parent-comp"
  @count
  
  def initialize
    @count = 0
  end
  
  def html
    %Q{
      <div>
        <h1>Parent Count: {count}</h1>
        <child-comp bind:child_count="{count}"></child-comp>
      </div>
    }
  end
  
  # ... rest of component
end

# Child component
class ChildComponent
  @tag_name = "child-comp"
  @child_count
  
  def initialize
    @child_count = 0
  end
  
  def reactables
    ["child_count"]
  end
  
  def html
    %Q{
      <div>
        <p>Child received: {child_count}</p>
      </div>
    }
  end
end
```

#### How It Works

1. Parent renders `<child-comp>` as a custom element
2. Child component registers itself with `customElements.define()`
3. Browser instantiates child Web Component
4. Parent's `bind:child_count="{count}"` creates reactive binding
5. When parent's `@count` changes:
   - `syncAttributes()` sets `child_count` attribute on child element
   - Child's `MutationObserver` detects attribute change
   - Child's setter is called with new value
   - Child re-renders

### Real-World Example (counter.rb)

```ruby
def html
  %Q{
    <div>
      <h1>Count: {count}</h1>
      <button on:click={increment}>+</button>
      <button on:click={decrement}>-</button>
      <plus-five bind:pfcount="{count}"></plus-five>
    </div>
  }
end
```

This creates a parent-child relationship where:
- Parent's `@count` is passed to child as `@pfcount`
- Changes in child don't affect parent (one-way binding)
- To enable two-way: child would emit events or parent listens to child

### Important Observations

1. **No Direct Children Support**: Components cannot have `{children}` placeholder in HTML
2. **No Slot API**: Web Components slots are not utilized
3. **Only Custom Element Nesting**: Child components must be custom elements (Web Components)
4. **Binding is One-Way**: Parent to child via `bind:` directive
5. **No Props Pattern**: No explicit props API; uses attributes + bindings

---

## 6. How to Implement a `<route>` Component

Based on the architecture, here's how a route component would work:

### Design Approach

```ruby
class Route
  @tag_name = "mochi-route"
  @match        # Path pattern to match against current URL
  @active       # Whether this route is active
  
  def initialize
    @match = ""
    @active = false
  end
  
  def reactables
    ["active"]
  end
  
  def html
    %Q{
      <div style="display: {display_style}">
        <slot></slot>
      </div>
    }
  end
  
  def css
    %Q{
      div {
        width: 100%;
      }
    }
  end
  
  def mounted(shadow_root, comp)
    # Listen to route changes from global router
    # Update @active based on pattern matching
  end
  
  private
  
  def display_style
    @active ? "block" : "none"
  end
end
```

### Key Challenges & Solutions

1. **Getting Match Attribute**
   - Extract from HTML attribute: `<mochi-route match="/users/:id">`
   - Need to add attribute extraction logic
   - Challenge: Match patterns with dynamic segments

2. **Detecting Current Route**
   - Listen to `window.popstate` events
   - Listen to browser's `hashchange` events
   - Problem: No global event system in Mochi

3. **Supporting Children/Slot Content**
   - Use Web Components `<slot>` element
   - Content inside `<mochi-route>...</mochi-route>` renders in slot
   - Challenge: Currently no slot usage in Mochi

### Implementation Strategy

#### Option A: Route Component + Global Router

```ruby
# Global router (singleton)
class GlobalRouter
  @@current_path = ""
  @@observers = []
  
  def self.register_observer(comp)
    @@observers << comp
    comp.check_match
  end
  
  def self.navigate(path)
    @@current_path = path
    @@observers.each { |obs| obs.check_match }
  end
  
  def self.current_path
    @@current_path
  end
end

# Route component
class Route
  @tag_name = "mochi-route"
  @match
  @active
  @component_ref  # Reference to web component instance
  
  def initialize
    @match = ""
    @active = false
  end
  
  def reactables
    ["active"]
  end
  
  def html
    %Q{
      <div style="display: #{@active ? 'block' : 'none'};">
        <slot></slot>
      </div>
    }
  end
  
  def mounted(shadow_root, comp)
    @component_ref = comp
    # Get match attribute from component element
    match_value = `#{comp}.getAttribute('match')`
    @match = match_value
    
    # Register with global router
    GlobalRouter.register_observer(self)
    
    # Check initial match
    check_match
  end
  
  def check_match
    current = GlobalRouter.current_path
    if matches_path?(current)
      @active = true if !@active
    else
      @active = false if @active
    end
    
    # Trigger re-render
    if `#{@component_ref}`
      `#{@component_ref}.render()`
    end
  end
  
  private
  
  def matches_path?(path)
    # Simple path matching
    # For now, exact match
    path == @match
  end
  
  def css
    %Q{
      :host {
        display: block;
        width: 100%;
      }
      div {
        width: 100%;
      }
    }
  end
end
```

#### Option B: Router-Aware Conditionals

```ruby
# In parent component
class App
  @tag_name = "app-root"
  @current_route
  
  def html
    %Q{
      <div>
        {if @current_route == "home"}
          <home-view></home-view>
        {end}
        {if @current_route == "users"}
          <users-view></users-view>
        {end}
        {if @current_route == "settings"}
          <settings-view></settings-view>
        {end}
      </div>
    }
  end
  
  def mounted(shadow_root, comp)
    @router = AppRouter.new do
      on '/' do
        @current_route = "home"
        `#{comp}.render()`
      end
      
      on '/users' do
        @current_route = "users"
        `#{comp}.render()`
      end
      
      on '/settings' do
        @current_route = "settings"
        `#{comp}.render()`
      end
    end
    
    @router.resolve
  end
end
```

### Recommended Approach for Mochi

Given Mochi's current architecture:

1. **Extend Web Components to support Slot API**
   - Modify WebComponentGenerator to emit `<slot></slot>`
   - Add slot content distribution support

2. **Add Attribute Access Pattern**
   - Allow components to read their own attributes: `@tag_name` → tag_name value
   - Or provide method: `get_attr(name)` → attribute value

3. **Global Event System**
   - Create a simple pub/sub system for route changes
   - Components can subscribe to route changes

4. **Route Component Implementation**
   ```ruby
   class MochiRoute
     @tag_name = "mochi-route"
     @match
     @active
     
     def reactables
       ["active"]
     end
     
     def html
       %Q{
         <slot></slot>
       }
     end
     
     def mounted(shadow_root, comp)
       # Extract match attribute from element
       @match = `#{comp}.getAttribute('match')`
       
       # Subscribe to global route changes
       `window.addEventListener('mochi-route-change', (e) => {
         #{comp}.rubyComp.handle_route_change(e.detail.path);
         #{comp}.render();
       })`
       
       # Set initial active state
       current = `window.location.pathname`
       @active = matches_path?(current)
     end
     
     def handle_route_change(path)
       @active = matches_path?(path)
     end
     
     private
     
     def matches_path?(path)
       # Simple pattern matching
       @match == path || @match == "*"
     end
     
     def css
       %Q{
         :host {
           display: #{@active ? 'block' : 'none'};
         }
       }
     }
   end
   ```

---

## 7. Key Framework Files Reference

### Core Compilation (Crystal)
- `compiler/src/mochi.cr` - Main transpiler entry point
- `compiler/src/ruby/ruby_understander.cr` - Parses Ruby component structure
- `compiler/src/html/conditional_processor.cr` - Handles {if}...{end} blocks
- `compiler/src/ruby/conditional_method_generator.cr` - Generates conditional methods
- `compiler/src/bind_extractor.cr` - Extracts bind: directives
- `compiler/src/webcomponents/web_component_generator.cr` - Creates JavaScript Web Components

### Runtime Library (Ruby)
- `ruby/lib/mochi.rb` - Mochi utilities (router, logger, fetch, etc.)

### Component Examples
- `ruby/lib/a/counter.rb` - Basic reactive component with events
- `ruby/lib/a/plus_five.rb` - Child component with binding
- `ruby/lib/a/router_demo.rb` - Router usage example

### Specifications & Plans
- `steps.md` - Implementation plan for Option C (pre-compiled conditionals)
- `cond.md` - Architecture options for conditional evaluation

---

## 8. Summary: How Mochi Components Work

### From Code to Running Component

```
1. WRITE: Ruby component class with @tag_name, html, css, methods
   ↓
2. COMPILE: Crystal transpiler analyzes Ruby
   - Extracts methods (html, css, reactables)
   - Processes conditionals → generates Ruby methods
   - Extracts bindings for child components
   - Generates getters/setters for reactables
   ↓
3. TRANSPILE: Ruby → JavaScript via Opal
   - All Ruby code (including generated methods) → JS
   - Ruby syntax → JavaScript equivalent
   - Instance variables → getters/setters
   ↓
4. GENERATE: Create Web Component class
   - Constructor: Instantiate Ruby object
   - connectedCallback: Initialize Shadow DOM + call mounted()
   - render(): Replace placeholders, evaluate conditionals
   - Attach event listeners for on:click, on:change
   - attributeChangedCallback: Handle attribute changes
   ↓
5. REGISTER: Define custom element
   - customElements.define("my-tag", MyComponentWebComp)
   ↓
6. RUN: Component in browser
   - User interacts → Event listener → Call Ruby method
   - Instance variable updates → syncAttributes
   - render() called → Shadow DOM updates
   - Conditionals re-evaluated → Display/hide elements
```

### Reactivity Model

```
Component State (Ruby instance variables)
    ↓
Reactables Array (declares which properties trigger re-render)
    ↓
Attribute Sync (shadow DOM attribute = state)
    ↓
Placeholder Replacement ({count} → actual value)
    ↓
Conditional Evaluation (data-cond-id → Ruby method)
    ↓
Render (shadow DOM innerHTML updated)
```

### Data Flow

```
HTML Placeholder:          {my_count}
   ↓
Gets value from:           this.rubyComp.$get_my_count()
   ↓
Which returns:             Ruby @my_count value
   ↓
Inserted into:             Shadow DOM innerHTML
   ↓
User sees:                 Current value rendered
```

### Key Design Principles

1. **Web Components First**: Uses native HTML5 standards
2. **Reactive Properties**: Declare reactables, let framework handle updates
3. **Ruby Syntax**: Write Ruby, get JavaScript for free
4. **Scoped Styling**: Shadow DOM isolates styles
5. **Method-Based Events**: Methods handle user interactions
6. **Compile-Time Processing**: Conditionals become methods at build time
7. **Binding System**: Parent-child data flow via bind: directive