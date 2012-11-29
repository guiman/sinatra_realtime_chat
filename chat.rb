require 'rubygems'
require 'sinatra/base'
require 'json'
require 'data_mapper'
require 'rack-google-analytics'
require 'sinatra/reloader'

DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_COPPER_URL'] || 'postgres://localhost/chatdb')

class Message
  include DataMapper::Resource
  
  property :id, Serial
  property :owner, String
  property :body, Text
  property :created_at, Time
    
  def to_json(*a)
    {
      'owner' => owner,
      'body'  => body,
      'created_at' => created_at
    }.to_json(*a)
  end
end

class User
  include DataMapper::Resource
  
  property :id, Serial
  property :username, String
  
  def to_json(*a)
    { 'username' => username }.to_json(*a)
  end
end

class StreamResponse
  attr_accessor :type, :data
  
  def initialize(type, data)
    @type = type
    @data = data
  end
  
  def build
    ret = { type: @type, message: @data }
    
    "data: #{ret.to_json}\n\n"
  end
  
end

# Initialize DataMapper
DataMapper.finalize.auto_migrate!

class ChatApp < Sinatra::Base
  use Rack::GoogleAnalytics, :tracker => 'UA-36406911-1'
  
  set server: 'thin', connections: []
  set :static_cache_control, [:public, {:max_age => 60 * 60 * 24 * 365}]
  
  # Configure Sinatra
  configure do
    enable :sessions
    register Sinatra::Reloader
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
    erb :login
  end

  get '/chat' do
    @messages = Message.all
    @users = User.all
    @user = User.first(username: session[:current_username])
  
    erb :chat
  end

  post '/say' do
    settings.connections.each { |out| out << StreamResponse.new(2, Message.create(owner: session[:current_username], body: params[:message])).build }
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
      settings.connections.each { |out| out << StreamResponse.new(0, { user_logged_in:  user }).build }
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
    settings.connections.each { |out| out << StreamResponse.new(1, { user_logged_out: user }).build }
    session.clear
  
    session[:flash]= "Hope to see ya soon!"
    redirect '/'
  end
end