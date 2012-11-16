require 'rubygems'
require 'sinatra'
require 'json'

set server: 'thin', users: [],  messages: [], connections: []

class Message
  attr_accessor :body
  attr_reader :owner, :created_at
  
  def initialize(owner, body = nil)
    @owner = owner
    @body = body
    @created_at = Time.now
  end
end

configure do
  enable :sessions
end

before do
  # Set flash sessions value
  if session[:flash]
    @flash= session[:flash]
    session[:flash] = nil
  else
    @flash = nil
  end
end

get '/' do
  redirect '/chat' if session[:current_username] && settings.users.include?(session[:current_username])
  erb :login
end

get '/chat' do
  redirect '/' if !settings.users.include?(session[:current_username]) || session[:current_username].nil?
  
  @messages = settings.messages
  @users = settings.users
  @user = session[:current_username]
  erb :chat
end

post '/say' do
  redirect '/' if !settings.users.include?(session[:current_username]) || session[:current_username].nil?
  
  msg = Message.new(session[:current_username], params[:message])
  
  settings.messages << msg
  
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
  if params[:username] && params[:username].strip != "" && !settings.users.include?(params[:username])
    settings.users << params[:username]
    session[:current_username] = params[:username]
    settings.connections.each { |out| out << "data: { \"type\": 0, \"user_logged_in\":\"#{params[:username]}\" }\n\n" }
    redirect '/chat'
  end
  
  session[:flash]= "Sorry, user already taken or invalid. Try using other or wait until he/she leaves, your choice."
  redirect '/'
end

get '/logout' do
  if session[:current_username]
    settings.users.delete session[:current_username]
    settings.connections.delete session[:conn]
    settings.connections.each { |out| out << "data: { \"type\": 1, \"user_logged_out\":\"#{session[:current_username]}\" }\n\n" }
    session.clear
  end
  
  session[:flash]= "Hope to see ya soon!"
  redirect '/'
end