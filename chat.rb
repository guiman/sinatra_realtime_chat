require 'rubygems'
require 'sinatra/base'
require 'json'
require 'data_mapper'
require 'rack-google-analytics'
require_relative 'model'

DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_COPPER_URL'] || 'postgres://localhost/chatdb')

# Initialize DataMapper
DataMapper.finalize.auto_migrate!

class ChatApp < Sinatra::Base
  use Rack::GoogleAnalytics, :tracker => 'UA-36406911-1'
  
  set server: 'thin', connections: []
  set :static_cache_control, [:public, {:max_age => 60 * 60 * 24 * 365}]
  
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
  
  # route definitions
  get '/' do
    expires(60 * 60 * 24 * 365, :public)
    erb :login
  end

  get '/chat' do
    @messages = Message.all
    @users = User.all
    @user = User.first(username: session[:current_username])
  
    erb :chat
  end

  post '/say' do
    message = Message.create(owner: session[:current_username], body: params[:message])
    settings.connections.each { |out| StreamResponse.new(:say, message).send(out) }
    halt(201, { message: "created correctly"}.to_json)
  end

  get '/stream', provides: 'text/event-stream' do
    stream :keep_open do |out|
      # store connection for later on
      settings.connections << out
      # remove connection when closed properly 
      out.callback { settings.connections.delete out }
      # remove connection when closed due to an error
      out.errback do
        logger.warn 'We just lost a connection!'
        settings.connections.delete out
      end
    end
  end

  post '/login' do
    if params[:username] && params[:username].strip != "" && User.first(username: params[:username]).nil? 
      # create user on the database
      user = User.create(username: params[:username])
      # set username for his/her session
      session[:current_username] = params[:username]
      # sending all connected users a notice that a new member arrived
      settings.connections.each { |out| StreamResponse.new(:login, { user_logged_in:  user }).send(out) }
      redirect '/chat'
    end
  
    session[:flash]= "Sorry, user already taken or invalid. Try using other or wait until he/she leaves, your choice."
    redirect '/'
  end

  get '/logout' do
    # removes from database and session
    user = User.first(username: session[:current_username])
    user.destroy
    # notify open connections that a user left
    settings.connections.each { |out| StreamResponse.new(:logout, { user_logged_out: user }).send(out) }
    session.clear
  
    session[:flash]= "Hope to see ya soon!"
    redirect '/'
  end
end