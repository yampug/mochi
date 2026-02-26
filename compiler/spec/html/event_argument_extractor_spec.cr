require "spec"
require "../../src/html/event_argument_extractor"

describe EventArgumentExtractor do
  it "extracts single argument" do
    html = %Q(<button onclick="{delete_item(item.id)}">Delete</button>)
    result = EventArgumentExtractor.process(html)
    
    result.should contain(%Q(onclick="{delete_item}"))
    result.should contain(%Q(data-mochi-arg-0="{item.id}"))
  end

  it "extracts multiple arguments" do
    html = %Q(<input onchange="{update_val(event, 5)}">)
    result = EventArgumentExtractor.process(html)
    
    result.should contain(%Q(onchange="{update_val}"))
    result.should contain(%Q(data-mochi-arg-0="{event}"))
    result.should contain(%Q(data-mochi-arg-1="{5}"))
  end
  
  it "ignores no arguments" do
    html = %Q(<button onclick="{save}">Save</button>)
    result = EventArgumentExtractor.process(html)
    
    result.should eq html
  end

  it "handles empty parentheses" do
    html = %Q(<button onclick="{save()}">Save</button>)
    result = EventArgumentExtractor.process(html)
    
    result.should eq %Q(<button onclick="{save}">Save</button>)
  end

  it "handles magical variables $event and $element" do
    html = %Q(<div onclick="{handle_click($event, $element, item.id)}"></div>)
    result = EventArgumentExtractor.process(html)

    result.should contain(%Q(onclick="{handle_click}"))
    result.should contain(%Q(data-mochi-arg-0="$event"))
    result.should contain(%Q(data-mochi-arg-1="$element"))
    result.should contain(%Q(data-mochi-arg-2="{item.id}"))
  end
end
