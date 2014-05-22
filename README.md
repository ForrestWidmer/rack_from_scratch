#Rack app from scratch.

#What is Rack?

Rack is a modular Ruby webserver that provides a minimal and adaptable interface for developing web apps. 

#How to you build a Rack App from scratch?

1. To build a rack app make sure you have the latest version of rack installed. Run `gem install rack`

2. Create a new directory to hold your app. `mkdir <app name>` To make this a Rack app, you need a Rackup file. Add a file under your parent dir. called `confid.ru`. (project_folder > [app name] > config.ru)

3. Inside the Rackup file (your config.ru file), create your class. I'm going to create a SayHello class. Within your class add a method called `call`.

```ruby
class SayHello
  def call

  end
end

```

4. All rack apps need to have a call method that takes an environment hash as an argument. It returns an array of a numeric HTTP status, hash of headers, and a response object. Add these to your `call` method.

```ruby
class SayHello
  def call(env)
    [200, {}, ["Hello World!"]] # HTTP status, header hash, response object
  end
end

```

5. Next, add the ability to run the app. Do this by creating a new instance of your class by adding `run SayHello.new` in your Rackup file.

```ruby
class SayHello
  def call(env)
    [200, {}, ["Hello World!"]]
  end
end

run SayHello.new

```

6. Make sure that you saved you're files then run `rackup` from the command line to start the server. It should default to port 9292 by default. 

```
~/code/sayhello$ rackup
> WEBrick 1.3.1
> ruby 1.9.3 (2014-02-24) [x86_64-darwin13.0.0]
> WEBrick::HTTPServer#start: pid=45122 port=9292

```
7. Your response string should now be visible in your browser. I used ["Hello World!"] so I just see the words "Hello World!" Since no content type header was defined, it defaulted to "text/plain". You can change this if you wish, I will change it to {"Content-Type" => "text/html"}.

8. Now, how does this work and where is the functionality coming from? When you run the `rackup` command the `start` method contained in the [Rack::Server](https://github.com/rack/rack/blob/master/lib/rack/server.rb) class is run and it includes several pieces of Rack middleware by default. See some below.

```
def self.middleware
      @middleware ||= begin
        m = Hash.new {|h,k| h[k] = []}
        m["deployment"].concat [
          [Rack::ContentLength],
          [Rack::Chunked],
          logging_middleware
        ]
        m["development"].concat m["deployment"] + [[Rack::ShowExceptions], [Rack::Lint]]
        m
      end
    end

```
  * [ShowExceptions](http://rack.rubyforge.org/doc/Rack/ShowExceptions.html) - Captures exceptions and creates the proper format to be sent back to your browser.
  * [Lint](http://rack.rubyforge.org/doc/Rack/Lint.html) - Lint will verify that our app is formatted properly and responding as it should.
  * [ContentLength](http://rack.rubyforge.org/doc/Rack/ContentLength.html) - Sets content-length in headers.
  * [Chunked](http://rack.rubyforge.org/doc/Rack/Chunked.html) - Applies chunked transfer encoding under certain conditions.
  * [CommonLogger](http://rack.rubyforge.org/doc/Rack/CommonLogger.html) - Logs requests to `$stderr`

9. Now that we know how to setup a super basic Rack environment and know some of the defualts middleware provided, lets reorganize things a bit. Lets copy the contents of `config.ru` and remove them with the exception of the new instance call. Let's place that content in it's own directory. Create a folder called `lib` and create a new file called sayhello.rb. Paste the previously copied contents in here. Back in the `config.ru` file, make sure to `require "sayhello"` so that the file gets loaded. Your two files should now look like this.

```
# config.ru

require "sayhello"

run SayHello.new

```

```
# app > lib > sayhello.rb

class SayHello
  def call(env)
    [200, {"Content-Type" => "text/html"}, ["Hello World!"]]
  end
end

```

10. As our app stands now, each time we edit a "required" file we'll need to restart our server. To prevent this, we'll add a piece of rack middleware called [Rack::Reloader](http://rack.rubyforge.org/doc/Rack/Reloader.html). To do this, add `use Rack::Reloader` in your `config.ru` file like so:

```
# config.ru

require "sayhello"

use Rack::Reloader

run SayHello.new

```

11. If you read the docs on [Rack::Reloader](http://rack.rubyforge.org/doc/Rack/Reloader.html) you'll notice there is a cooldown period. We can override this like so: `use Rack::Reloader, 0`. After making these changes restart your server but this time append `-Ilib` to your rackup command: `rackup -Ilib` Doing this will include the `lib` dir. so our app can find our `sayhello.rb` file. Going back to localhost:9292 should display the same content as when everything was in the same file.

12. Now we passed our response directly into our `call` method. Rack makes this much easier by providing `Rack::Response` which is far more convenient and allows the setting of cookies/headers and provides a default 200 OK status. Your class should now look like the code below and your browser should display the response object as before.

```
# app > lib > sayhello.rb

class SayHello
  def call(env)
    Rack::Response.new("Say Hello!")
  end
end

```
13. At this point your probably thinking that you want to display more then just some strings in your browser. Rather then passing in long strings of HTML you can render out templates. To do this you just need to `require "erb"` in your class then define the render method. 

```
def render(template)
  path = File.expand_path("../views/#{template}", __FILE__)
  ERB.new(File.read(path)).result(binding)
end

```

   The render method takes a template as an argument. We then set `path` to equal the path to our file by calling File.expand_path (`expand_path` converts a pathname to an absolute pathname) and set that as relative to this file (__FILE__). We then call ERB.new and read in the file then call result on that and pass in `binding` so that we have access to all the methods defined here.

   (Result executes the generated code to produce a complete template and returns the result of that code. Binding encapsulates the execution context and retains it for future use.)

   So whats happening here is that we are creating a new ERB object with the template being defined as path, path being the location of the file passed in to render. 

   You can now add `render("index.html.erb") as the arg to Rack::Response.new. `Rack::Response.new(render("index.html.erb")).

14. Add your desired html format inside the index.html.erb file then reload your browser. Ta da!

15. Our app is really basic and only responding to one request. we can change this by using the `Rack::Request` object and passing it into our environment. Lets add some conditions to diplay a 404 "Not Found" view if the user requests an invalid path.

```
request = Rack::Request.new(env)
case request.path
when "/" then Rack::Response.new(render("index.html.erb"))
else
  Rack::Response.new("Not Found", 404)
end

```

   Now if a user attempts to visit localhost:9292/some/path it will display a 404 page saying "Not Found"

16. Now we will probably want some form of user input. Let's add the ability for a user to add there name for a personal greeting. 
  * Lets add a basic HTML POST form where action="/change", a text input field where name="name" as well as a submit button.
  * Now we are pointing to the "/change" route so let's add that now. Under the current `when` case in the case statement add a new condition:

```
when "/change"
  Rack::Response.new do |response|
    response.set_cookie("sayhello", request.params["name"])
    response.redirect("/")
  end
...
...

```

   * So when the route is "/change" we're going to generate a new Response object by passing in a block. We're going to set the cookie as "sayhello" with the value of the request params, the "name" value in the form. We're then going to redirect to the "Home" view.

   * Next, back in the index.html.erb file, add the call: <%= hello_name %> (or whatever you want to call it) where you want the user input to appear. I did: `<h1>Hello <%= hello_name %>!</h1>

   * Now of course we need to build this method. Add the following method to your class.

```
def hello_name
  @request.cookies["sayhello"] || "World"
end

```

  * Basically we are calling the value of the cookie name "sayhello" or the word "World". In order to use it like this though request needs to be an instance variable, so change the calls to `request` in your file to `@request`.

  *Done! Reload your view and change the name.

17. There is more functionality that can be added such as using a stylesheet as opossed to putting styles in the view, handling multiple requests, etc. Brows through the source code in the app to see how this is done. Now you have a very basic although functioning Rack app.