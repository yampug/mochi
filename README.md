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
Mochi provides also native [Sorbet](https://sorbet.org) support for all that type-checking goodness. This can normally be a bit daunting to get going yourself, since Sorbet doesn't play nice with Opal out of the box, so Mochi got your back.

So all in all Mochi brings type-safe Ruby to the modern web.
The project is still very early on its journey, so proceed at your own risk for now.

> **⚠️ Under Heavy Construction:**
> Mochi is currently under heavy development and is not yet ready for production use. APIs may change without notice, and features may be incomplete or unstable. Use at your own risk.


## Getting Started

If you want to get your hands dirty and try out Mochi for yourself, I prepared over at [yampug/mochi-starter-template](https://github.com/yampug/mochi-starter-template) a preconfigured starter template, which should make the first steps as easy as possible.

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
Prerequisites:
* <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/yampug/mochi/blob/main/github/assets/crystal_dark.png?raw=true">
    <source media="(prefers-color-scheme: light)" srcset="https://github.com/yampug/mochi/blob/main/github/assets/crystal_light.png?raw=true">
    <img alt="Crystallang Icon" style="height: 16px; background: white; border-radius: 50%; padding: 1px;" src="https://github.com/yampug/mochi/blob/main/github/assets/crystal_light.png?raw=true">
  </picture> https://crystal-lang.org
* <img alt="Opal Ruby Icon" style="height: 16px;" src="https://github.com/yampug/mochi/blob/main/github/assets/opal_icon.ico?raw=true"> [Opal](https://opalrb.com)
* <img alt="Task Go Icon" style="height: 16px;" src="https://github.com/yampug/mochi/blob/main/github/assets/task_icon.ico?raw=true"> [Task](https://taskfile.dev)
* <img alt="Ruby Icon" style="height: 16px;" src="https://www.ruby-lang.org/favicon.ico"/> [Ruby](https://www.ruby-lang.org/)
* <img alt="Sorbet Icon" style="height: 16px;" src="https://sorbet.org/img/favicon.ico"/> [Sorbet](https://sorbet.org/)

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
mochi -i "/path/to/my/beautiful/ruby_code" -o "/path/where/I/want/to/output" -m --typecheck
```

* -i: input directory
* -o: output directory
* -m: Minimise the generated js code (Optional)
* --typecheck: Run Sorbet Typechecks (Optional)
* --initialize: Creates a new preconfigured project directory



## License

[MIT](LICENSE.md)
