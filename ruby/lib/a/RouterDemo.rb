require "a/hello_sayer"
# typed: true

class RouterDemo

  @tag_name = "router-demo"
  @route

  def initialize
    @route = "def"
  end

  def reactables
    ["route"]
  end

  def html
    %Q{
      <div>
        Router Demo {route}
        <div>
          {if @route == "root"}
            <p style="background: green; padding: 10px; border-radius: 8px;">ROOT ROUTE</p>
            <plus-five></plus-five>
          {end}
        </div>
      </div>
    }
  end

  def css
    %Q{
      
    }
  end

  def mounted(shadow_root, comp)
    router = AppRouter.new do
      on '/' do
        puts "Welcome to the Home Page!"
        `#{comp}.rubyComp.route = "root"`
        `#{comp}.syncAttributes()`
      end

      on '/users/:id/posts/:post_id' do |params|
        puts "User ID: #{params['id']}, Post ID: #{params['post_id']}"
      end

      not_found do
        puts "404 - Page Not Found!"
      end
    end

    # manual input
    router.resolve_manual('/', nil)
    router.resolve_manual("/users/123/posts/abc", nil)

    # automatic input from current browser location
    router.resolve
  end

  def unmounted
  end
end
