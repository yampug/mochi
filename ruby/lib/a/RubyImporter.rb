require "a/hello_sayer"
# typed: true

class RubyImportComp

  @tag_name = "ruby-importer"
  @pfcount

  def initialize
    @pfcount = 0
  end

  def reactables
    ["pfcount"]
  end

  def html
    %Q{
      <div>
        Ruby Importer
      </div>
    }
  end

  def css
    %Q{
      
    }
  end

  def increment
    @pfcount = @pfcount + 1
  end

  def mounted
    HelloSayer::say_hello
  end

  def unmounted
  end
end
