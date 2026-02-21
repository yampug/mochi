require "spec"
require "../../src/tree-sitter/dependency_graph_generator"

describe TreeSitter::DependencyGraphGenerator do
  it "maps simple variables to text paths" do
    source = <<-RUBY
    class Counter
      def initialize
        @count = 0
      end

      def inc
        @count += 1
      end

      def html
        "<div><span>{\@count}</span></div>"
      end
    end
    RUBY

    result = TreeSitter::DependencyGraphGenerator.generate(source)
    
    deps = result.dependencies
    deps.keys.should eq ["@count"]
    
    ops = deps["@count"]
    ops.size.should eq 1
    
    op = ops.first
    op.path.should eq [0, 0, 0]
    op.type.should eq "text"
    op.attr_name.should be_nil
  end

  it "maps attribute variables" do
    source = <<-RUBY
    class Button
      def initialize
        @active = "btn-active"
      end
      
      def toggle
        @active = ""
      end

      def html
        "<button class={\@active}>Click</button>"
      end
    end
    RUBY

    result = TreeSitter::DependencyGraphGenerator.generate(source)
    
    deps = result.dependencies
    deps.keys.should eq ["@active"]
    
    ops = deps["@active"]
    ops.size.should eq 1
    
    op = ops.first
    op.path.should eq [0]
    op.type.should eq "attribute"
    op.attr_name.should eq "class"
  end

  it "maps multiple occurrences of the same variable" do
    source = <<-RUBY
    class UserBadge
      def initialize
        @name = "Bob"
      end
      
      def rename
        @name = "Alice"
      end

      def html
        "<div title={\@name}><span>{\@name}</span></div>"
      end
    end
    RUBY

    result = TreeSitter::DependencyGraphGenerator.generate(source)
    
    deps = result.dependencies
    deps.keys.should eq ["@name"]
    
    ops = deps["@name"]
    ops.size.should eq 2
    
    # either order based on lexbor walk
    attr_op = ops.find(&.type.==("attribute")).not_nil!
    text_op = ops.find(&.type.==("text")).not_nil!
    
    attr_op.path.should eq [0]
    attr_op.attr_name.should eq "title"
    
    text_op.path.should eq [0, 0, 0]
    text_op.attr_name.should be_nil
  end
end
