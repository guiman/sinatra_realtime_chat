Bundler.require
require_relative 'model'

DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_COPPER_URL'] || 'postgres://localhost/chatdb')

# Initialize DataMapper
DataMapper.finalize.auto_migrate!

class ChatApp < Sinatra::Base
  use Rack::GoogleAnalytics, :tracker => 'UA-36406911-1'

  set server: 'thin', connections: []

  # Configure Sinatra
  configure do
    enable :sessions
  end

  # before statements
  ['/chat', '/say', '/logout'].each do |path|
    before path do
      redirect '/' if session[:current_username].nil? || User.first(username: session[:current_username]).nil?
    end
  end

  before '/' do
    redirect '/chat' if session[:current_username] && !User.first(username: session[:current_username]).nil?
  end

  # after statements
  ['/chat', '/'].each do |path|
    after path do
      session['flash']= nil
    end
  end

  get '/' do
    erb :login
  end

  get '/chat' do
    @user = User.first(username: session[:current_username])
    erb :chat
  end

  get '/messages' do
    @messages = Message.all

    content_type :json
    @messages.to_json
  end

  get '/users' do
    @users = User.all

    content_type :json
    @users.to_json
  end

  post '/socket' do
    halt(400, { message: "not a websocket request" }.to_json ) unless request.websocket?
    request.websocket do |ws|
      ws.onopen do
        settings.connections << ws
      end

      ws.onmessage do |msg|
        EM.next_tick do
          settings.sockets.each { |s| s.send(msg) }
        end
      end

      ws.onclose do
        warn("websocket closed")
        settings.connections.delete(ws)
      end
    end
    Message.create(owner: session[:current_username], body: params[:message])
  end

  post '/login' do
    if params[:username] && params[:username].strip != "" && User.first(username: params[:username]).nil?
      User.create(username: params[:username])
      session[:current_username] = params[:username]
      redirect '/chat'
    end

    session[:flash]= "Sorry, user already taken or invalid. Try using other or wait until he/she leaves, your choice."
    redirect '/'
  end

  get '/logout' do
    # removes from database and session
    user = User.first(username: session[:current_username])
    user.destroy
    session.clear

    session[:flash]= "Hope to see ya soon!"
    redirect '/'
  end
end
