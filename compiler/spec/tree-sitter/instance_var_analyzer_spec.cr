require "spec"
require "../../src/tree-sitter/instance_var_analyzer"

describe TreeSitter::InstanceVarAnalyzer do
  it "categorizes manual assigned variables correctly" do
    source = <<-RUBY
    class Counter
      def initialize
        @count = 0
        @name = "Test"
      end

      def inc
        @count += 1
      end

      def html
        "<div>{\@count}</div>"
      end

      def print_name
        puts @name
      end
    end
    RUBY

    vars = TreeSitter::InstanceVarAnalyzer.analyze(source)
    count_var = vars.find(&.name.==("@count")).not_nil!
    name_var = vars.find(&.name.==("@name")).not_nil!

    count_var.category.should eq TreeSitter::InstanceVarAnalyzer::Category::State
    count_var.is_bound.should be_true
    count_var.writes.should eq 2

    name_var.category.should eq TreeSitter::InstanceVarAnalyzer::Category::Constant
    name_var.is_bound.should be_false
    name_var.writes.should eq 1
    name_var.reads.should eq 1
  end

  it "handles attr_accessor and attr_reader" do
    source = <<-RUBY
    class UserInfo
      attr_accessor :user_id
      attr_reader :session

      def html
        "<span>{\@user_id} - {\@session}</span>"
      end
    end
    RUBY

    vars = TreeSitter::InstanceVarAnalyzer.analyze(source)
    user_id = vars.find(&.name.==("@user_id")).not_nil!
    session = vars.find(&.name.==("@session")).not_nil!

    user_id.category.should eq TreeSitter::InstanceVarAnalyzer::Category::State
    user_id.is_bound.should be_true
    # because user_id has attr_accessor
    user_id.attr_mutated.should be_true

    session.category.should eq TreeSitter::InstanceVarAnalyzer::Category::Derived
    # Because "session" only has attr_reader and reads in string:
    # 0 manual writes inside or outside the constructor
    session.attr_mutated.should be_false
    session.is_bound.should be_true
  end

  it "handles purely derived variables with standard ruby interpolation" do
    source = <<-RUBY
    class Profile
      def get_full_name
        "\#{@first} \#{@last}"
      end

      def html
        "<div>\#{get_full_name}</div>"
      end
    end
    RUBY

    vars = TreeSitter::InstanceVarAnalyzer.analyze(source)
    first_var = vars.find(&.name.==("@first")).not_nil!
    last_var = vars.find(&.name.==("@last")).not_nil!

    first_var.category.should eq TreeSitter::InstanceVarAnalyzer::Category::Derived
    last_var.category.should eq TreeSitter::InstanceVarAnalyzer::Category::Derived

    first_var.reads.should eq 1
    first_var.is_bound.should be_false # used in get_full_name, not html directly
  end
end
