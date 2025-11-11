# require "spec"
# require "../../src/routes/route_parser"

# describe RouteParser do
#     it "parse config" do
#         content = File.read("../ruby/routes.yaml")
#         routes = RouteParser.parse(content)

#         routes.size.should eq(3)

#         routes[0].name.should eq("root_route")
#         routes[0].envs.should eq(["staging", "prod"])
#         routes[0].path.should eq("/abc")
#         routes[0].component.should eq("common/AbcComponent")
#         routes[0].kind.should eq("")
#         routes[0].vars.should eq({"config" => "a"})

#         routes[1].name.should eq("root_route_local")
#         routes[1].envs.should eq(["local"])
#         routes[1].path.should eq("/abc")
#         routes[1].component.should eq("common/AbcComponent")
#         routes[1].kind.should eq("")
#         routes[1].vars.should eq({"config" => "b"})

#         routes[2].name.should eq("not_found")
#         routes[2].envs.should eq(["all"])
#         routes[2].path.should eq("*")
#         routes[2].component.should eq("error/NotFoundComponent")
#         routes[2].kind.should eq("fallback")
#         routes[2].vars.should eq({"config" => "a"})
#     end
# end