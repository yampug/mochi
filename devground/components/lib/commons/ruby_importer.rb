require "commons/hello_sayer"
# typed: true

class RubyImportComp

  @tag_name = "ruby-importer"

  def initialize
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

  def mounted
    HelloSayer::say_hello
  end

  def unmounted
  end
end
