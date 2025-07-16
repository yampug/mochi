<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/yampug/mochi/blob/main/github/assets/banner_dark.png?raw=true">
    <source media="(prefers-color-scheme: light)" srcset="https://github.com/yampug/mochi/blob/main/github/assets/banner_light.png?raw=true">
    <img alt="Mochi Banner" src="https://github.com/yampug/mochi/blob/main/github/assets/banner_light.png?raw=true">
  </picture>
</p>

[![License](https://img.shields.io/badge/license-MIT-green?labelColor=gray)](LICENSE.md)

## What is Mochi?

Mochi brings modern web development to [Ruby](https://www.ruby-lang.org/) by leveraging the excellent work from [Opal](https://opalrb.com/) and tighly coupling it with the open [Web Components](https://developer.mozilla.org/en-US/docs/Web/API/Web_components) standard.
Mochi provides also native [Sorbet](https://sorbet.org) support for all that type-checking goodness, as this can be a bit daunting to get going yourself, since Sorbet doesn't play nice will Opal out of the box. 

So all in all Mochi brings type-safe Ruby to the modern web.
The project is still very early on its journey, so proceed at your own risk for now.

## Getting Started

Over at [yampug/mochi-starter-template](https://github.com/yampug/mochi-starter-template) you find a preconfigured starter tempalte make the first steps as easy as possible.

### Example Component
A simple example counter component with 2 buttons to increment and decrement the current count:

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
      <div class="wrapper">
        <h1>Count: {count}</h1>
        <button on:click={increment}>Increment</button>
        <button on:click={decrement}>Decrement</button>
      </div>
    }
  end

  def css
    %Q{
      .wrapper {
        background: red;
      }
    }
  end

  def increment
    @count = @count + 1
  end

  def decrement
    @count = @count - 1
  end

  def mounted
    puts "Counter mounted"
  end

  def unmounted
    puts "Counter unmounted"
  end
end

```

### Compiling
Prerequestities:
* [Crystal](https://crystal-lang.org) 
* [Task](https://taskfile.dev) 

```
git clone http://github.com/yampug/mochi
cd mochi
task build
```

### Usage

#### Creating a new project
```
mochi --initialize="my_fancy_project"
```

#### Compiling your code
```
mochi -i "/path/to/my/beautiful/ruby_code" -o "/path/where/I/want/to/output" -m -tc
```

* -i: input directory
* -o: output directory
* -m: Minimise the generated js code (Optional) 
* -tc: Run Sorbet Typechecks (Optional) 
* --initialize: Creates a new preconfigured project directory 



## License

[MIT](LICENSE.md)
