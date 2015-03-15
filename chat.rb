Bundler.require
Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
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

  get '/socket' do
    request.websocket do |ws|
      ws.onopen do
        settings.connections << ws
        settings.connections.each { |conn| StreamResponse.new(:login, {}).send(conn) }
      end

      ws.onmessage do |msg|
        request_parser = ParseRequest.new(msg)
        response = request_parser.response

        if request_parser.propagate_response
          settings.connections.each { |conn| response.send(conn) }
        else
          response.send(ws)
        end
      end

      ws.onclose do
        warn("websocket closed")
        settings.connections.delete(ws)
        settings.connections.each { |conn| StreamResponse.new(:logout, {}).send(conn) }
      end
    end
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
