require "spec"
require "../../src/html/each_processor"
require "../../src/webcomponents/legacy_component_generator"
require "../../src/html/conditional_processor"

describe LegacyComponentGenerator do
  describe "each block comment anchor generation" do
    it "replaces each blocks with comment anchors in processed HTML" do
      html = "<div>{each @items as item, index}<p>{index}</p>{end}</div>"
      result = EachProcessor.process(html)

      result.html.should contain("<!--each-anchor-0-->")
      result.html.should_not contain("mochi-each")
      result.each_blocks.size.should eq(1)
      result.each_blocks[0].loop_def.array_name.should eq("@items")
    end

    it "preserves each block content as template data" do
      html = "<ul>{each @items as item, index}<li>{index}</li>{end}</ul>"
      result = EachProcessor.process(html)

      result.each_blocks[0].content.should contain("<li>{index}</li>")
    end
  end

  describe "generate_each_init_code" do
    it "generates comment anchor lookup and template creation" do
      block = EachBlock.new(
        EachLoopDef.new("@items", "item", "index"),
        "\n<p>{index}</p>\n",
        0, 40, 20, 0
      )
      code = LegacyComponentGenerator.generate_each_init_code([block])

      code.should contain("each-anchor-0")
      code.should contain("document.createElement('template')")
      code.should contain("createNodeIterator")
      code.should contain("this._eachAnchors[0]")
      code.should contain("this._eachItems[0] = []")
      code.should contain("this._reconcileEachBlock(0)")
    end

    it "returns empty string for no each blocks" do
      code = LegacyComponentGenerator.generate_each_init_code([] of EachBlock)
      code.should eq("")
    end
  end

  describe "generate_each_update_code" do
    it "generates reconcile call for each block" do
      block = EachBlock.new(
        EachLoopDef.new("@items", "item", "index"),
        "<p>{index}</p>",
        0, 30, 15, 0
      )
      code = LegacyComponentGenerator.generate_each_update_code([block])

      code.should contain("this._reconcileEachBlock(0)")
    end

    it "generates reconcile calls for multiple blocks" do
      blocks = [
        EachBlock.new(EachLoopDef.new("@items", "item", "index"), "<li>{index}</li>", 0, 30, 10, 0),
        EachBlock.new(EachLoopDef.new("@rows", "row", "i"), "<tr>{i}</tr>", 40, 70, 50, 1),
      ]
      code = LegacyComponentGenerator.generate_each_update_code(blocks)

      code.should contain("this._reconcileEachBlock(0)")
      code.should contain("this._reconcileEachBlock(1)")
    end

    it "returns empty string for no each blocks" do
      code = LegacyComponentGenerator.generate_each_update_code([] of EachBlock)
      code.should eq("")
    end
  end

  describe "generate (full component)" do
    it "includes LIS helpers and reconcile logic" do
      block = EachBlock.new(
        EachLoopDef.new("@items", "item", "index"),
        "\n<div>{index}</div>\n",
        0, 50, 25, 0
      )
      gen = LegacyComponentGenerator.new
      component = gen.generate(
        "MyList",
        "my-list",
        "div { color: red; }",
        "<div><!--each-anchor-0--></div>",
        "[\"count\"]",
        {} of String => String,
        [] of ConditionalBlock,
        [block]
      )

      js = component.js_code
      js.should contain("_computeLIS(arr)")
      js.should contain("_substituteItemVars(root, item, index)")
      js.should contain("_reconcileEachBlock(blockId)")
      js.should contain("each-anchor-0")
      js.should contain("this._eachTemplates")
      js.should contain("this._eachAnchors")
      js.should contain("this._eachItems")
    end

    it "does not use mochi-each element queries in generated code" do
      block = EachBlock.new(
        EachLoopDef.new("@items", "item", "i"),
        "<li>{i}</li>",
        0, 30, 15, 0
      )
      gen = LegacyComponentGenerator.new
      component = gen.generate(
        "MyItems",
        "my-items",
        "",
        "<ul><!--each-anchor-0--></ul>",
        "[]",
        {} of String => String,
        [] of ConditionalBlock,
        [block]
      )

      component.js_code.should_not contain("querySelectorAll('mochi-each')")
      component.js_code.should_not contain("mochi-each")
    end

    it "reactive text nodes are cached and updated without innerHTML reset" do
      gen = LegacyComponentGenerator.new
      component = gen.generate(
        "Counter",
        "my-counter",
        "",
        "<p>{count}</p>",
        "[\"count\"]",
        {} of String => String
      )

      js = component.js_code
      js.should contain("this._rnCache")
      js.should contain("paintCount === 0")
      # The innerHTML is only set on first render
      js.should contain("this.shadow.innerHTML")
    end
  end
end
