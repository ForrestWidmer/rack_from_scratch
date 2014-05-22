require "erb"

class SayHello

  def self.call(env)
    new(env).response.finish # Will convert to array format.
  end

  def initialize(env)
    @request = Rack::Request.new(env)
  end

  def response
    case @request.path
    when '/' then Rack::Response.new(render("index.html.erb"))
    when "/change" 
      Rack::Response.new do |response|
        response.set_cookie("sayhello", @request.params["name"])
        response.redirect("/")
      end
    else
      Rack::Response.new("Not Found", 404)
    end
  end

  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    ERB.new(File.read(path)).result(binding)
  end

  def hello_name
    @request.cookies["sayhello"] || "World"
  end
end