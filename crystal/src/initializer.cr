require "file_utils"

class Initializer
  
  def initialize(project_name : String)
    puts "Init '#{project_name}'"
    
    proj_path = "./#{project_name}"
    
    if Dir.exists?(proj_path)
      puts "Aborting, project '#{project_name}' already exists..."
    else
      Dir.mkdir_p(proj_path)
      src_path = "#{proj_path}/lib"
      Dir.mkdir_p(src_path)
    
      
      File.write("#{proj_path}/Taskfile.yml", generate_taskfile)
      File.write("#{proj_path}/Gemfile", generate_gemfile)
      File.write("#{proj_path}/index.html", generate_index_html)
      File.write("#{src_path}/MyCounter.rb", generate_my_first_mochi_component)

    end
  end 
  
  def generate_taskfile : String
    <<-'YML'
    version: '3'
    
    tasks:
      build:
        cmds:
          - mochi -i "./lib" -o "./build" -m
    YML
  end
  
  def generate_gemfile : String
    <<-'TEXT'
    source "https://rubygems.org"
    
    gem "opal", "~> 1.8"
    gem "opal-browser", "~> 0.3.5"
    
    gem 'sorbet', :group => :development
    gem 'sorbet-runtime'
    gem 'tapioca', require: false, :group => [:development, :test]
    TEXT
  end
  
  def generate_index_html : String
    <<-'HTML'
    <html>
        <head>
            <title>Mochi Starter</title>
            <script
              src="./build/opal-runtime.js"
              onload='Opal.require("native"); Opal.require("promise"); Opal.require("browser/setup/full");'></script>
            <script src="./build/bundle.js"></script>
        </head>
        <body>
            <my-counter count="3"></my-counter>
            <my-counter count="4"></my-counter>
        </body>
    </html>
    HTML
  end
  
  def generate_my_first_mochi_component : String
    <<-'RUBY'
    class MyCounter
    
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
        puts "MyCounter mounted"
      end
    
      def unmounted
        puts "MyCounter unmounted"
      end
    end
    RUBY
      
  end

end