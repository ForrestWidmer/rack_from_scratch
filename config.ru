require "sayhello"

use Rack::Reloader
use Rack::ContentType, "text/html"
use Rack::Auth::Basic do |username, password|
  password == "Password"
end

run Rack::Cascade.new([Rack::File.new("public"), SayHello])