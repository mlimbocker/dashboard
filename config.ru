require 'sinatra/cyclist'
require 'dashing'

configure do
  set :auth_token, 'YOUR_AUTH_TOKEN'

  helpers do
    def protected!
     # Put any authentication code you want in here.
     # This method is run before accessing any resource.
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

set :routes_to_cycle_through, [:default, :zendesk, :github]

get "/default" do
	"Default"
end

get "/zendesk" do
	"Zendesk"
end

get "/github" do
	"GitHub"
end

run Sinatra::Application