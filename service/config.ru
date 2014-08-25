require 'rubygems'
require 'rack'
require 'bundler'
Bundler.require

require File.join(File.dirname(__FILE__), "lib", "health")

use Rack::Static,
  :urls => ["/images", "/js", "/css", "/favicon.ico"],
  :root => "public"

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

      # TODO: Make this sql
      @recents = RecentSearch.dataset.reverse_order(:created_at).limit(50).to_a.uniq{ |s| s[:repo] }.take(10)

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

      params = Rack::Utils.parse_nested_query(req.query_string)

      health_json = {}
      begin
        health_json = Health.new.health_json_from_repo("#{owner_name}/#{repo_name}")

        if(params["src"] == "site")
          RecentSearch.dataset.insert({:repo => "#{owner_name}/#{repo_name}", :created_at => Time.now})
        end
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
      
      # TODO: Make this sql
      # TODO: Dry this up from /search/*/*
      @recents = RecentSearch.dataset.reverse_order(:created_at).limit(50).to_a.uniq{ |s| s[:repo] }.take(10)

      [
        200,
        { 'Content-Type' => 'text/html' },
        [ERB.new(File.read(File.join(File.dirname(__FILE__), "views", "index.html.erb"))).result(binding)]
      ]
    end    
  }
])
