require 'rubygems'
require 'sinatra'
require 'json'
require 'data_mapper'
require 'rack-google-analytics'

use Rack::GoogleAnalytics, :tracker => 'UA-36406911-1'
set server: 'thin', connections: []
DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/chatdb')

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

DataMapper.finalize.auto_migrate!

configure do
  enable :sessions
end

before do
  # set flash sessions value
  if session[:flash]
    @flash= session[:flash]
    session[:flash] = nil
  else
    @flash = nil
  end
end

before '/chat' do
  @users ||= []
end

get '/' do
  redirect '/chat' if session[:current_username] && !User.first(username: session[:current_username]).nil?
  
  erb :login
end

get '/chat' do
  redirect '/' if !User.all(username: session[:current_username]).any? || session[:current_username].nil?
  
  @messages = Message.all
  @users = User.all
  @user = User.first(username: session[:current_username])
  
  erb :chat
end

post '/say' do
  redirect '/' if !User.all(username: session[:current_username]).any? || session[:current_username].nil?
  
  msg = Message.create(owner: session[:current_username], body: params[:message])
    
  settings.connections.each { |out| out << "data: { \"type\": 2, \"owner\": \"#{msg.owner}\", \"body\": \"#{msg.body}\", \"created_at\": \"#{msg.created_at.strftime("%F %r")}\" }\n\n" }
end

get '/stream', provides: 'text/event-stream' do
  stream :keep_open do |out|
    # store connection for later on
    settings.connections << out
    # remove connection when closed properly 
    out.callback { settings.connections.delete(out) }
    # remove connection when closed due to an error
    out.errback do
      logger.warn 'we just lost a connection!'
      settings.connections.delete(out)
    end
  end
end

post '/login', provides: 'text/event-stream' do
  if params[:username] && params[:username].strip != "" && User.first(username: params[:username]).nil?
    # create user on database and set username for his/her session
    User.create(username: params[:username])
    session[:current_username] = params[:username]
    # sending all connected users a notice that a new member arrived
    settings.connections.each { |out| out << "data: { \"type\": 0, \"user_logged_in\":\"#{params[:username]}\" }\n\n" }
    
    redirect '/chat'
  end
  
  session[:flash]= "Sorry, user already taken or invalid. Try using other or wait until he/she leaves, your choice."
  redirect '/'
end

get '/logout' do
  if session[:current_username] && !User.first(username: session[:current_username]).nil?
    # removes from database and session
    User.first(username: session[:current_username]).destroy
    settings.connections.delete session[:conn]
    # notify open connections that a user left
    settings.connections.each { |out| out << "data: { \"type\": 1, \"user_logged_out\":\"#{session[:current_username]}\" }\n\n" }
    session.clear
  end
  
  session[:flash]= "Hope to see ya soon!"
  redirect '/'
end