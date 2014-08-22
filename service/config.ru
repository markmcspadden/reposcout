require 'rubygems'
require 'rack'
require 'bundler'
Bundler.require

require File.join(File.dirname(__FILE__), "lib", "health")

use Rack::Static,
  :urls => ["/images", "/js", "/css"],
  :root => "public"
# use Rack::BounceFavicon

class Router
  def initialize(routes)
    @routes = routes
  end
  def default
    [ 404, {'Content-Type' => 'text/plain'}, ['file not found'] ]
  end
  def call(env)
    @routes.each do |route|
      match = env['REQUEST_PATH'].match(route[:pattern])
      if match
        return route[:controller].call( env, match )
      end
    end
    default
  end

end

# use Rack::Auth::Basic, "Protected Area" do |username, password|
#   (username == '' && password == '')
# end

run Router.new([
  {
    :pattern => /\/search\/(.*)\/(.*)/,
    :controller => lambda do |env, match|
      owner_name = match[1]
      repo_name = match[2]

      req = Rack::Request.new(env)
      
      @owner_name = owner_name
      @repo_name = repo_name

      @repo = "#{@owner_name}/#{@repo_name}"

      [
        200,
        { 'Content-Type' => 'text/html' },
        [ERB.new(File.read(File.join(File.dirname(__FILE__), "views", "index.html.erb"))).result(binding)]
      ]
    end
  },
  {
    :pattern => /\/(.*)\/(.*)\/health/,
    :controller => lambda do |env, match|
      owner_name = match[1]
      repo_name = match[2]

      req = Rack::Request.new(env)

      health_json = {}
      begin
        health_json = Health.new.health_json_from_repo("#{owner_name}/#{repo_name}")
      # rescue
      #   puts "Uh oh..."
      end
      
      [
        200,
        { 'Content-Type' => 'application/json' },
        [health_json.to_json]
      ]
    end
  },
  # / needs to be last for pattern matching
  {
    :pattern => "/",
    :controller => lambda do |env, match|
      req = Rack::Request.new(env)
      
      [
        200,
        { 'Content-Type' => 'text/html' },
        [ERB.new(File.read(File.join(File.dirname(__FILE__), "views", "index.html.erb"))).result]
      ]
    end    
  },
  # {
  #   :pattern => %r{^/api/.*$},
  #   :controller => lambda do |env, match|
  #     req = Rack::Request.new(env)
  #     if ENV['RACK_ENV'] == 'production'
  #       url = 'instacation-rails.herokuapp.com'
  #     else
  #       url = 'localhost:8081'
  #     end
  #     path = req.fullpath.sub(/\/api\//, '')
  #     # puts "http://#{url}/#{path}"
  #     [
  #       200,
  #       { 'Content-Type' => 'application/json' },
  #       [RestClient.get("http://#{url}/#{path}")]
  #     ]
  #   end
  # },
  # {
  #   :pattern => %r{^/(chain.html)?$},
  #   :controller => lambda do |env, match|
  #     req = Rack::Request.new(env)
  #     [
  #       200,
  #       {
  #         'Content-Type'  => 'text/html',
  #         'Cache-Control' => 'public, max-age=86400'
  #       },
  #       File.open("public/chain.html", File::RDONLY)
  #     ]
  #   end
  # },
  # {
  #   :pattern => %r{^/property.html*},
  #   :controller => lambda do |env, match|
  #     req = Rack::Request.new(env)
  #     puts req.query_string
  #     [
  #       200,
  #       {
  #         'Content-Type'  => 'text/html',
  #         'Cache-Control' => 'public, max-age=86400'
  #       },
  #       File.open("public/property.html", File::RDONLY)
  #     ]
  #   end
  # }
])
