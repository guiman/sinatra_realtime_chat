require 'rubygems'
require 'sinatra'
require 'json'
require 'redis'
require 'rack-google-analytics'

use Rack::GoogleAnalytics, :tracker => 'UA-36406911-1'
set server: 'thin', connections: [], db: Redis.new

class Message
  attr_accessor :body
  attr_reader :owner, :created_at
  
  def initialize(owner, body = nil, created_at = nil)
    @owner = owner
    @body = body
    
    if created_at
      @created_at = Time.parse created_at
    else
      @created_at = Time.now 
    end
  end
  
  def self.create(values)
    self.new(values["owner"], values["body"], values["created_at"])
  end
  
  def to_json(*a)
    {
      'owner' => owner,
      'body'  => body,
      'created_at' => created_at
    }.to_json(*a)
  end
end

configure do
  enable :sessions
end

before do
  # initialize database
  settings.db.set("users", [].to_json) if settings.db.get("users").nil?
  settings.db.set("messages", [].to_json) if settings.db.get("messages").nil?
  
  # set flash sessions value
  if session[:flash]
    @flash= session[:flash]
    session[:flash] = nil
  else
    @flash = nil
  end
  
  # db values population
  @users = JSON::parse settings.db.get("users")
end

get '/' do
  redirect '/chat' if session[:current_username] && @users.include?(session[:current_username])
  
  erb :login
end

get '/chat' do
  redirect '/' if !@users.include?(session[:current_username]) || session[:current_username].nil?
  
  @messages = (JSON::parse settings.db.get("messages")).collect { |message| Message.create message }
  
  @user = session[:current_username]
  erb :chat
end

post '/say' do
  redirect '/' if !@users.include?(session[:current_username]) || session[:current_username].nil?
  
  msg = Message.new(session[:current_username], params[:message])
  
  messages = JSON::parse settings.db.get("messages")
  messages << msg
  settings.db.set "messages", messages.to_json
  
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
  if params[:username] && params[:username].strip != "" && !@users.include?(params[:username])
    @users << params[:username]
    settings.db.set "users", @users.to_json
    session[:current_username] = params[:username]
    settings.connections.each { |out| out << "data: { \"type\": 0, \"user_logged_in\":\"#{params[:username]}\" }\n\n" }
    redirect '/chat'
  end
  
  session[:flash]= "Sorry, user already taken or invalid. Try using other or wait until he/she leaves, your choice."
  redirect '/'
end

get '/logout' do
  if session[:current_username]
    @users.delete session[:current_username]
    settings.db.set "users", @users.to_json
    settings.connections.delete session[:conn]
    settings.connections.each { |out| out << "data: { \"type\": 1, \"user_logged_out\":\"#{session[:current_username]}\" }\n\n" }
    session.clear
  end
  
  session[:flash]= "Hope to see ya soon!"
  redirect '/'
end