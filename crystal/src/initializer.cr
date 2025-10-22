require "file_utils"
require "./generated/builtins/my_counter_rb"

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
          - mochi -i "./" -o "./build" -m
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
            <link rel="preconnect" href="https://fonts.googleapis.com">
            <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
            <link href="https://fonts.googleapis.com/css2?family=Caprasimo&display=swap" rel="stylesheet">
            <style>
                body {
                    background: #24262c;
                }
                .logo-block {
                    display: flex;
                    justify-content: center;
                    gap: 22px;
                    align-items: anchor-center;
                    color: white;
                    width: 100%;
                    font-family: "Caprasimo", serif;
                    font-weight: 400;
                    font-style: normal;
                }
                .logo { height: 64px; }
            </style>
        </head>
        <body>
            <div class="logo-block">
                <img class="logo" src="https://github.com/yampug/mochi/blob/main/devground/mochi.png?raw=true"/>
                <h1>Hello Mochi</h1>
            </div>
            <div>
                <my-counter count="3"></my-counter>
            </div>
        </body>
    </html>
    HTML
  end

  def generate_my_first_mochi_component : String
    return MyCounterRbFragment.get_ruby_code
  end

end
